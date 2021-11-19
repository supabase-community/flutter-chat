import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_quickstart/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_quickstart/models/message.dart';
import 'package:supabase_quickstart/models/room.dart';
import 'package:supabase_quickstart/utils/constants.dart';

part 'rooms_state.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit() : super(RoomInitial());

  /// List of rooms
  List<Room> _rooms = [];
  StreamSubscription<List<Room>>? _roomsSubscription;
  bool _haveCalledGetRooms = false;

  final Map<String, StreamSubscription<List<String>>>
      _participantsSubscription = {};

  void getRooms(BuildContext context) {
    if (_haveCalledGetRooms) {
      return;
    }
    _haveCalledGetRooms = true;
    _roomsSubscription = supabase
        .from('rooms')
        .stream()
        .execute()
        .map((data) => data.map(Room.fromMap).toList())
        .listen((rooms) {
      for (final room in rooms) {
        _getParticipants(context: context, roomId: room.id);
      }
      _rooms = rooms;
      emit(RoomLoaded(_rooms));
    });
  }

  void _getParticipants({
    required BuildContext context,
    required String roomId,
  }) {
    if (_participantsSubscription[roomId] != null) {
      return;
    }
    _participantsSubscription[roomId] = supabase
        .from('user_room:room_id=eq.$roomId')
        .stream()
        .execute()
        .map((data) => data.map((row) => row['user_id'] as String).toList())
        .listen((participants) {
      final index = _rooms.indexWhere((room) => room.id == roomId);
      _rooms[index] = _rooms[index].copyWith(participants: participants);
      emit(RoomLoaded(_rooms));
    });
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    for (var listener in _participantsSubscription.values) {
      listener.cancel();
    }
    return super.close();
  }
}
