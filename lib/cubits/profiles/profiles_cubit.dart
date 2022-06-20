import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase_chat/models/profile.dart';
import 'package:supabase_chat/utils/constants.dart';

part 'profiles_state.dart';

class ProfilesCubit extends Cubit<AppUserState> {
  ProfilesCubit() : super(ProfilesInitial());

  String? _selfUserId;

  /// AppUser object of the logged in user
  Profile? _self;

  /// Map of app users cache in memory with user_id as the key
  final Map<String, Profile?> _appUsers = {};
  final Map<String, StreamSubscription<Profile?>> _appUserSubscriptions = {};

  void getProfile(String userId, {bool isSelf = false}) {
    if (_appUserSubscriptions[userId] != null) {
      return;
    }
    if (isSelf) {
      _selfUserId = userId;
    }

    _appUserSubscriptions[userId] = supabase
        .from('users:id=eq.$userId')
        .stream(['id'])
        .execute()
        .map((data) => data.isEmpty ? null : Profile.fromMap(data.first))
        .listen((appUser) {
          _appUsers[userId] = appUser;
          if (isSelf) {
            _self = appUser;
          }
          if (_self != null) {
            emit(ProfilesLoaded(appUsers: _appUsers, self: _self!));
          } else {
            emit(NoProfile());
          }
        });
  }

  Future<void> updateProfile({
    required String name,
  }) async {
    try {
      final updates = {'id': _selfUserId, 'name': name};
      final res = await supabase.from('users').upsert(updates).execute();
      final error = res.error;
      if (error != null) {
        throw error;
      }
    } catch (e) {
      if (_self == null) {
        emit(NoProfile());
      } else {
        emit(ProfilesLoaded(appUsers: _appUsers, self: _self!));
      }
      rethrow;
    }
  }
}
