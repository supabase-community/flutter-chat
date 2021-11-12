import 'package:flutter/material.dart';
import 'package:supabase_quickstart/components/auth_state.dart';

/// Page to redirect users to the correct destinations
class SplashPage extends StatefulWidget {
  /// Page to redirect users to the correct destinations
  const SplashPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) {
      return const SplashPage();
    });
  }

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends AuthState<SplashPage> {
  @override
  void initState() {
    recoverSupabaseSession();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
