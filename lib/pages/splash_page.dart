import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_quickstart/components/auth_state.dart';
import 'package:supabase_quickstart/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_quickstart/pages/account_page.dart';
import 'package:supabase_quickstart/pages/rooms_page.dart';

/// Page to redirect users to the correct destinations
class SplashPage extends StatefulWidget {
  /// Page to redirect users to the correct destinations
  const SplashPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const SplashPage());
  }

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends AuthState<SplashPage> {
  @override
  void initState() {
    super.initState();
    recoverSupabaseSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUserCubit, AppUserState>(
      /// Redirect the user to the appropreate page depending on the AppUserState
      listener: (context, state) {
        if (state is AppUserLoaded) {
          /// If a user profile is found, take them to RoomsPage
          Navigator.of(context)
              .pushAndRemoveUntil(RoomsPage.route(), (_) => false);
        } else if (state is AppUserNoProfile) {
          /// If no profile is found, take them to AccountPage to first create profile
          Navigator.of(context).pushAndRemoveUntil(
              AccountPage.route(isRegistering: true), (_) => false);
        }
      },
      child: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
