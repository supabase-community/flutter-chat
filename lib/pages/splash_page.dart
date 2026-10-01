import 'package:flutter/material.dart';
import 'package:flutter_chat/utils/constants.dart';

/// Page shown until the initial auth state is known.
class const SplashPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: preloader);
  }
}
