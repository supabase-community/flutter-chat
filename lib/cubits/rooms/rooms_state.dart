part of 'rooms_cubit.dart';

@immutable
abstract class RoomState {}

class RoomsLoading extends RoomState {}

class RoomsLoaded extends RoomState {
  final List<AppUser> newUsers;
  final List<Room> rooms;

  RoomsLoaded({
    required this.rooms,
    required this.newUsers,
  });
}

class RoomsEmpty extends RoomState {
  final List<AppUser> newUsers;

  RoomsEmpty({required this.newUsers});
}

class RoomsError extends RoomState {
  final String message;

  RoomsError(this.message);
}
