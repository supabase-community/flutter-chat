import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_chat/cubits/profiles/profiles_cubit.dart';
import 'package:supabase_chat/utils/constants.dart';

/// Widget that will display a user's avatar
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    Key? key,
    required this.userId,
  }) : super(key: key);

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, AppUserState>(
      builder: (context, state) {
        if (state is ProfilesLoaded) {
          final user = state.appUsers[userId];
          return CircleAvatar(
            child:
                user == null ? preloader : Text(user.username.substring(0, 2)),
          );
        } else {
          return const CircleAvatar(child: preloader);
        }
      },
    );
  }
}
