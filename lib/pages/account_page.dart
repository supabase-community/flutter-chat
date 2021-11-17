import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_quickstart/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_quickstart/utils/constants.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) {
      return const AccountPage();
    });
  }

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();

  /// Called when user taps `Update` button
  void _updateProfile() {
    final userName = _usernameController.text;
    BlocProvider.of<AppUserCubit>(context).updateProfile(name: userName);
    Navigator.of(context).pop();
  }

  Future<void> _signOut() async {
    final response = await supabase.auth.signOut();
    final error = response.error;
    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocConsumer<AppUserCubit, AppUserState>(
        listener: (context, state) {
          if (state is AppUserLoaded) {
            _usernameController.text = state.self.name;
          }
        },
        builder: (context, state) {
          if (state is AppUserLoaded) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'User Name'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                    onPressed: _updateProfile, child: const Text('Save')),
                const SizedBox(height: 18),
                TextButton(onPressed: _signOut, child: const Text('Sign Out')),
              ],
            );
          }
          return preloader;
        },
      ),
    );
  }
}
