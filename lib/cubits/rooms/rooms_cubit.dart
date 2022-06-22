import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_chat/cubits/profiles/profiles_cubit.dart';
import 'package:supabase_chat/models/profile.dart';
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

  late final String _myUserId;

  /// List of new users of the app for the user to start talking to
  late final List<Profile> _newUsers;

  /// List of rooms
  List<Room> _rooms = [];
  StreamSubscription<List<Map<String, dynamic>>>? _rawRoomsSubscription;
  bool _haveCalledGetRooms = false;

  final Map<String, bool> _participantsSubscription = {};

  Future<void> getRooms(BuildContext context) async {
    if (_haveCalledGetRooms) {
      return;
    }
    _haveCalledGetRooms = true;

    _myUserId = supabase.auth.user()!.id;

    final res = await supabase
        .from('profiles')
        .select()
        .not('id', 'eq', _myUserId)
        .order('created_at')
        .limit(12)
        .execute();
    final error = res.error;
    if (error != null) {
      emit(RoomsError('Error loading new users'));
      return;
    }
    final data = List<Map<String, dynamic>>.from(res.data as List);
    _newUsers = data.map(Profile.fromMap).toList();

    /// Get realtime updates on rooms that the user is in
    _rawRoomsSubscription = supabase
        .from('room_participants')
        .stream(['room_id', 'profile_id'])
        .execute()
        .listen((participantMaps) async {
          if (participantMaps.isEmpty) {
            emit(RoomsEmpty(newUsers: _newUsers));
          }

          _rooms = participantMaps
              .map(Room.fromRoomParticipants)
              .where((room) => room.opponentUserId != _myUserId)
              .toList();
          for (final room in _rooms) {
            _getNewestMessage(context: context, roomId: room.id);
            BlocProvider.of<ProfilesCubit>(context)
                .getProfile(room.opponentUserId);
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
    _rawRoomsSubscription?.cancel();
    _messagesProvider.clear();
    return super.close();
  }
}
