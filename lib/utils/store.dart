import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:supabase_quickstart/models/app_user.dart';
import 'package:supabase_quickstart/utils/constants.dart';

/// Data store to store in memory app data
/// without any state management packages
class Store {
  static final Store _singleton = Store._internal();

  factory Store() {
    return _singleton;
  }

  Store._internal();

  /// Map of app users cache in memory with user_id as the key
  final Map<String, AppUser> _appUsers = {};
  final _appUsersController = BehaviorSubject<Map<String, AppUser>>();
  Stream<Map<String, AppUser>> get appUsersStream => _appUsersController.stream;
  final Map<String, StreamSubscription<AppUser>> _appUserSubscriptions = {};

  void getProfile(String userId) {
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
      _appUsersController.add(_appUsers);
    });
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
  }) async {
    _appUsers[userId] = _appUsers[userId]!.copyWith(name: name);
    _appUsersController.add(_appUsers);
    final updates = {'id': userId, 'username': name};
    final response = await supabase.from('profiles').upsert(updates).execute();
    final error = response.error;
    if (error != null) _appUsersController.addError(error);
  }
}
