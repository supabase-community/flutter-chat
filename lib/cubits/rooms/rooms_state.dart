part of 'rooms_cubit.dart';

@immutable
abstract class RoomState {}

class RoomsInitial extends RoomState {}

class RoomsLoaded extends RoomState {
  final List<Room> rooms;

  RoomsLoaded(this.rooms);
}

class RoomsError extends RoomState {
  final String message;

  RoomsError(this.message);
}
