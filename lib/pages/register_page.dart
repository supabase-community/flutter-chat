import 'package:flutter/material.dart';
import 'package:supabase_chat/pages/rooms_page.dart';
import 'package:supabase_chat/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key, required this.isRegistering}) : super(key: key);

  static Route<void> route({bool isRegistering = false}) {
    return MaterialPageRoute(
      builder: (context) => AccountPage(isRegistering: isRegistering),
    );
  }

  final bool isRegistering;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: _isLoading
          ? preloader
          : Form(
              key: _formKey,
              child: ListView(
                padding: listViewPadding,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      label: Text('Email'),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  spacer,
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      label: Text('Password'),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Required';
                      }
                      if (val.length < 6) {
                        return '6 characters minimum';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  spacer,
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      label: Text('Username'),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Required';
                      }
                      final isValid =
                          RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(val);
                      if (!isValid) {
                        return '3-24 long with alphanumeric or underscore';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  spacer,
                  ElevatedButton(
                    onPressed: () async {
                      final isValid = _formKey.currentState!.validate();
                      if (!isValid) {
                        return;
                      }
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      final username = _usernameController.text;
                      final res = await Supabase.instance.client.auth.signUp(
                          email, password,
                          userMetadata: {'username': username});
                      final error = res.error;
                      if (error != null) {
                        context.showErrorSnackBar(message: error.message);
                      }
                      Navigator.of(context).push(RoomsPage.route());
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
    );
  }
}
