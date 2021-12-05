import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase_chat/models/app_user.dart';
import 'package:supabase_chat/utils/constants.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserInitial());

  String? _selfUserId;

  /// AppUser object of the logged in user
  AppUser? _self;

  /// Map of app users cache in memory with user_id as the key
  final Map<String, AppUser?> _appUsers = {};
  final Map<String, StreamSubscription<AppUser?>> _appUserSubscriptions = {};

  void getProfile(String userId, {bool isSelf = false}) {
    if (_appUserSubscriptions[userId] != null) {
      return;
    }
    if (isSelf) {
      _selfUserId = userId;
    }

    _appUserSubscriptions[userId] = supabase
        .from('users:id=eq.$userId')
        .stream()
        .execute()
        .map((data) => data.isEmpty ? null : AppUser.fromMap(data.first))
        .listen((appUser) {
      _appUsers[userId] = appUser;
      if (isSelf) {
        _self = appUser;
      }
      if (_self != null) {
        emit(AppUserLoaded(appUsers: _appUsers, self: _self!));
      } else {
        emit(AppUserNoProfile());
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
        emit(AppUserNoProfile());
      } else {
        emit(AppUserLoaded(appUsers: _appUsers, self: _self!));
      }
      rethrow;
    }
  }
}
