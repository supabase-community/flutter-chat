part of 'profiles_cubit.dart';

@immutable
abstract class AppUserState {}

class ProfilesInitial extends AppUserState {}

class ProfilesLoaded extends AppUserState {
  ProfilesLoaded({
    required this.appUsers,
    required this.self,
  });

  final Map<String, Profile?> appUsers;
  final Profile self;
}

/// State where the logged in user has not been registered yet.
class NoProfile extends AppUserState {}
