part of 'app_user_cubit.dart';

@immutable
abstract class AppUserState {}

class AppUserInitial extends AppUserState {}

class AppUserLoaded extends AppUserState {
  AppUserLoaded({
    required this.appUsers,
    required this.self,
  });

  final Map<String, AppUser?> appUsers;
  final AppUser self;
}

/// State where the logged in user has not been registered yet.
class AppUserNoProfile extends AppUserState {}

/// State where the user is updating the profile
class AppUserUpdating extends AppUserState {}
