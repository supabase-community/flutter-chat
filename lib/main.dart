import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_chat/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_chat/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: Replace credentials with your own
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANONKEY',
  );
  runApp(const MyApp());
}

/// Entry of the entire app
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppUserCubit>(
      create: (context) => AppUserCubit(),
      child: MaterialApp(
        title: 'SupaChat',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.green,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              primary: Colors.green,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              onPrimary: Colors.white,
              primary: Colors.green,
            ),
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
