import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:supabase_quickstart/models/app_user.dart';
import 'package:supabase_quickstart/models/room.dart';
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
  final _appUsersStreamController = BehaviorSubject<Map<String, AppUser>>();
  Stream<Map<String, AppUser>> get appUsersStream =>
      _appUsersStreamController.stream;
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
      _appUsersStreamController.add(_appUsers);
    });
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
  }) async {
    _appUsers[userId] = _appUsers[userId]!.copyWith(name: name);
    _appUsersStreamController.add(_appUsers);
    final updates = {'id': userId, 'username': name};
    final response = await supabase.from('profiles').upsert(updates).execute();
    final error = response.error;
    if (error != null) _appUsersStreamController.addError(error);
  }

  /// List of rooms
  List<Room> _rooms = [];
  final _roomsController = BehaviorSubject<List<Room>>();
  Stream<List<Room>> get roomStream => _roomsController.stream;
  bool _haveCalledGetRooms = false;

  void getRooms() {
    if (_haveCalledGetRooms) {
      return;
    }
    _haveCalledGetRooms = true;
    supabase
        .from('rooms')
        .stream()
        .execute()
        .map((data) => data.map(Room.fromMap).toList())
        .listen((rooms) {
      _rooms = rooms;
      _roomsController.add(_rooms);
    });
  }
}
