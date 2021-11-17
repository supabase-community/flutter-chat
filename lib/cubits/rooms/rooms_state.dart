part of 'rooms_cubit.dart';

@immutable
abstract class RoomState {}

class RoomInitial extends RoomState {}

class RoomLoaded extends RoomState {
  final List<Room> rooms;

  RoomLoaded(this.rooms);
}

class RoomError extends RoomState {
  final String message;

  RoomError(this.message);
}
