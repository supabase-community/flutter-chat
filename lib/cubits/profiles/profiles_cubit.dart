import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase_chat/models/profile.dart';
import 'package:supabase_chat/utils/constants.dart';

part 'profiles_state.dart';

class ProfilesCubit extends Cubit<AppUserState> {
  ProfilesCubit() : super(ProfilesInitial());

  /// Map of app users cache in memory with user_id as the key
  final Map<String, Profile?> _profiles = {};

  Future<void> getProfile(
    String userId, {

    /// Whether this call is for getting my own profile or not
    bool isSelf = false,
  }) async {
    if (_profiles[userId] != null) {
      return;
    }

    final res = await supabase
        .from('users')
        .select()
        .match({'id': userId})
        .single()
        .execute();
    final data = res.data as Map<String, dynamic>?;
    if (data == null) {
      return;
    }
    _profiles[userId] = Profile.fromMap(data);

    emit(ProfilesLoaded(appUsers: _profiles));
  }
}
