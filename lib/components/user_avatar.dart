import 'package:flutter/material.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/utils/constants.dart';

/// Widget that will display a user's avatar
class UserAvatar extends StatelessWidget {
  const UserAvatar(
    this.profile, {
    Key? key,
  }) : super(key: key);

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child:
          profile == null ? preloader : Text(profile!.username.substring(0, 2)),
    );
  }
}
