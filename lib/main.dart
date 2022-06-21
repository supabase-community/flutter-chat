import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_chat/cubits/profiles/profiles_cubit.dart';
import 'package:supabase_chat/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_chat/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: Replace credentials with your own
    url: 'https://idqmkztyldhxrkiolexz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkcW1renR5bGRoeHJraW9sZXh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTU3MDM5MjcsImV4cCI6MTk3MTI3OTkyN30.tu8dJdZdgrxDe_91_iTQNzS_xaN0djIXDw8u5Ehc2u4',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilesCubit>(
      create: (context) => ProfilesCubit(),
      child: MaterialApp(
        title: 'SupaChat',
        theme: appTheme,
        home: const SplashPage(),
      ),
    );
  }
}
