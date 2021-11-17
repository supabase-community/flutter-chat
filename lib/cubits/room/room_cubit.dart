import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_quickstart/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_quickstart/models/message.dart';
import 'package:supabase_quickstart/models/room.dart';
import 'package:supabase_quickstart/utils/constants.dart';

part 'room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit() : super(RoomInitial());

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

  Stream<List<Message>> getMessagesStream({
    required String roomId,
    required BuildContext context,
  }) {
    return supabase
        .from('messages:room_id=eq.$roomId')
        .stream()
        .execute()
        .map((data) => data.map((row) {
              final message = Message.fromMap(row);
              BlocProvider.of<AppUserCubit>(context).getProfile(message.userId);
              return message;
            }).toList());
  }
}
