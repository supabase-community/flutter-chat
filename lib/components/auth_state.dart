import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_chat/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_chat/pages/login_page.dart';
import 'package:supabase_chat/pages/splash_page.dart';
import 'package:supabase_chat/utils/constants.dart';

class AuthState<T extends StatefulWidget> extends SupabaseAuthState<T> {
  @override
  void onUnauthenticated() {
    if (mounted) {
      Navigator.of(context)
          .pushAndRemoveUntil(LoginPage.route(), (route) => false);
    }
  }

  @override
  void onAuthenticated(Session session) {
    if (mounted) {
      if (session.user != null) {
        BlocProvider.of<AppUserCubit>(context)
            .getProfile(session.user!.id, isSelf: true);
      }
      if (this is! SplashPageState) {
        Navigator.of(context)
            .pushAndRemoveUntil(SplashPage.route(), (route) => false);
      }
    }
  }

  @override
  void onPasswordRecovery(Session session) {}

  @override
  void onErrorAuthenticating(String message) {
    context.showErrorSnackBar(message: message);
  }
}
