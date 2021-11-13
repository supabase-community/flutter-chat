import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_quickstart/components/auth_required_state.dart';
import 'package:supabase_quickstart/models/app_user.dart';
import 'package:supabase_quickstart/utils/constants.dart';
import 'package:supabase_quickstart/utils/store.dart';

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

class _AccountPageState extends AuthRequiredState<AccountPage> {
  final _usernameController = TextEditingController();
  String? _userId;
  final _store = Store();

  /// Called when user taps `Update` button
  void _updateProfile() {
    final userName = _usernameController.text;
    _store.updateProfile(userId: _userId!, name: userName);
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
  void onAuthenticated(Session session) {
    final user = session.user;
    if (user != null) {
      _userId = user.id;
      _store.getProfile(user.id);
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
      body: _userId == null
          ? preloader
          : StreamBuilder<AppUser?>(
              stream: _store.appUsersStream
                  .map((appUserMap) => appUserMap[_userId!]),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return preloader;
                }
                final appUser = snapshot.data;
                if (appUser == null) {
                  return preloader;
                }
                return ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  children: [
                    TextFormField(
                      initialValue: appUser.name,
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'User Name'),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                        onPressed: _updateProfile, child: const Text('Save')),
                    const SizedBox(height: 18),
                    TextButton(
                        onPressed: _signOut, child: const Text('Sign Out')),
                  ],
                );
              }),
    );
  }
}
