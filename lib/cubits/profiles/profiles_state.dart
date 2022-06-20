part of 'profiles_cubit.dart';

@immutable
abstract class AppUserState {}

class ProfilesInitial extends AppUserState {}

class ProfilesLoaded extends AppUserState {
  ProfilesLoaded({
    required this.appUsers,
  });

  final Map<String, Profile?> appUsers;
}
