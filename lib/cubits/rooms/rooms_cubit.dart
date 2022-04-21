import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_chat/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_chat/models/app_user.dart';
import 'package:supabase_chat/models/message.dart';
import 'package:supabase_chat/models/room.dart';
import 'package:supabase_chat/utils/constants.dart';
import 'package:supabase_chat/utils/messages_provider.dart';

part 'rooms_state.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit({required MessagesProvider messagesProvider})
      : _messagesProvider = messagesProvider,
        super(RoomsLoading());

  final MessagesProvider _messagesProvider;

  final Map<String, StreamSubscription<Message?>> _messageSubscriptions = {};

  late final String _userId;

  /// List of new users of the app for the user to start talking to
  late final List<AppUser> _newUsers;

  /// List of rooms
  List<Room> _rooms = [];
  StreamSubscription<List<Room>>? _roomsSubscription;
  bool _haveCalledGetRooms = false;

  final Map<String, StreamSubscription<List<String>>>
      _participantsSubscription = {};

  Future<void> getRooms(BuildContext context) async {
    if (_haveCalledGetRooms) {
      return;
    }
    _haveCalledGetRooms = true;

    _userId = supabase.auth.user()!.id;

    final res = await supabase
        .from('users')
        .select()
        .not('id', 'eq', _userId)
        .order('created_at')
        .limit(12)
        .execute();
    final error = res.error;
    if (error != null) {
      emit(RoomsError('Error loading new users'));
    }
    final data = List<Map<String, dynamic>>.from(res.data as List);
    _newUsers = data.map(AppUser.fromMap).toList();

    /// Get realtime updates on rooms that the user is in
    _roomsSubscription = supabase
        .from('rooms')
        .stream(['id'])
        .execute()
        .map((data) => data.map(Room.fromMap).toList())
        .listen((rooms) {
          for (final room in rooms) {
            _getParticipants(context: context, roomId: room.id);
            _getNewestMessage(context: context, roomId: room.id);
          }
          _rooms = rooms;
          if (_rooms.isEmpty) {
            emit(RoomsEmpty(newUsers: _newUsers));
          } else {
            emit(RoomsLoaded(newUsers: _newUsers, rooms: _rooms));
          }
        });
  }

  /// Loads the participants in each room and their profile
  void _getParticipants({
    required BuildContext context,
    required String roomId,
  }) {
    if (_participantsSubscription[roomId] != null) {
      return;
    }
    _participantsSubscription[roomId] = supabase
        .from('user_room:room_id=eq.$roomId')
        .stream(['id'])
        .execute()
        .map((data) => data.map((row) => row['user_id'] as String).toList())
        .listen((participantUserIds) {
          final index = _rooms.indexWhere((room) => room.id == roomId);
          final opponentUserId =
              participantUserIds.singleWhere((element) => element != _userId);
          _rooms[index] =
              _rooms[index].copyWith(opponentUserId: opponentUserId);
          for (final userId in participantUserIds) {
            BlocProvider.of<AppUserCubit>(context).getProfile(userId);
          }
          emit(RoomsLoaded(
            newUsers: _newUsers,
            rooms: _rooms,
          ));
        });
  }

  // Setup listeners to listen to the most recent message in each room
  void _getNewestMessage({
    required BuildContext context,
    required String roomId,
  }) {
    _messageSubscriptions[roomId] = _messagesProvider
        .subscribe(roomId)
        .map((messages) => messages.isEmpty ? null : messages.first)
        .listen((message) {
      final index = _rooms.indexWhere((room) => room.id == roomId);
      _rooms[index] = _rooms[index].copyWith(lastMessage: message);
      _rooms.sort((a, b) {
        /// Sort according to the last message
        /// Use the room createdAt when last message is not available
        final aTimeStamp =
            a.lastMessage != null ? a.lastMessage!.createdAt : a.createdAt;
        final bTimeStamp =
            b.lastMessage != null ? b.lastMessage!.createdAt : b.createdAt;
        return bTimeStamp.compareTo(aTimeStamp);
      });
      emit(RoomsLoaded(
        newUsers: _newUsers,
        rooms: _rooms,
      ));
    });
  }

  /// Creates or returns an existing roomID of both participants
  Future<String> createRoom(String opponentUserId) async {
    final res = await supabase.rpc('create_new_room',
        params: {'opponent_uid': opponentUserId}).execute();
    final error = res.error;
    if (error != null) {
      throw error;
    }
    emit(RoomsLoaded(rooms: _rooms, newUsers: _newUsers));
    return res.data as String;
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    for (final listener in _participantsSubscription.values) {
      listener.cancel();
    }
    _messagesProvider.clear();
    return super.close();
  }
}
