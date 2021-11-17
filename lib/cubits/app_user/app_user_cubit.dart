import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase_quickstart/models/app_user.dart';
import 'package:supabase_quickstart/utils/constants.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserInitial());

  /// Map of app users cache in memory with user_id as the key
  AppUser? _self;
  final Map<String, AppUser> _appUsers = {};
  final Map<String, StreamSubscription<AppUser>> _appUserSubscriptions = {};

  void getProfile(String userId, {bool isSelf = false}) {
    if (_appUserSubscriptions[userId] != null) {
      return;
    }
    _appUserSubscriptions[userId] = supabase
        .from('users:id=eq.$userId')
        .stream()
        .execute()
        .map((data) => AppUser.fromMap(data.first))
        .listen((appUser) {
      _appUsers[userId] = appUser;
      if (isSelf) {
        _self = appUser;
      }
      if (_self != null) {
        emit(AppUserLoaded(appUsers: _appUsers, self: _self!));
      }
    });
  }

  Future<void> updateProfile({
    required String name,
  }) async {
    _appUsers[_self!.id] = _appUsers[_self!.id]!.copyWith(name: name);
    final updates = {'id': _self!.id, 'username': name};
    await supabase.from('profiles').upsert(updates).execute();
  }
}
