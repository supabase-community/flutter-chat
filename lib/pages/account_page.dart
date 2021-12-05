import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_chat/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_chat/pages/splash_page.dart';
import 'package:supabase_chat/utils/constants.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key, required this.isRegistering}) : super(key: key);

  static Route<void> route({bool isRegistering = false}) {
    return MaterialPageRoute(builder: (context) {
      return AccountPage(isRegistering: isRegistering);
    });
  }

  final bool isRegistering;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocBuilder<AppUserCubit, AppUserState>(
        builder: (context, state) {
          if (state is AppUserInitial) {
            return preloader;
          } else if (state is AppUserUpdating) {
            return preloader;
          } else if (state is AppUserLoaded) {
            return _ProfileEditingWidget(
              isRegistering: isRegistering,
              initialUserName: state.self.name,
            );
          } else if (state is AppUserNoProfile) {
            return _ProfileEditingWidget(
              isRegistering: isRegistering,
            );
          }
          throw UnimplementedError();
        },
      ),
    );
  }
}

class _ProfileEditingWidget extends StatefulWidget {
  const _ProfileEditingWidget({
    Key? key,
    required this.isRegistering,
    this.initialUserName = '',
  }) : super(key: key);

  final bool isRegistering;
  final String initialUserName;

  @override
  __ProfileEditingWidgetState createState() => __ProfileEditingWidgetState();
}

class __ProfileEditingWidgetState extends State<_ProfileEditingWidget> {
  String userName = '';
  bool isLoading = false;

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    try {
      setState(() {
        isLoading = true;
      });
      await BlocProvider.of<AppUserCubit>(context)
          .updateProfile(name: userName);
      if (widget.isRegistering) {
        Navigator.of(context)
            .pushAndRemoveUntil(SplashPage.route(), (route) => false);
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      context.showErrorSnackBar(message: 'Failed to update profile');
    }
  }

  Future<void> _signOut() async {
    final response = await supabase.auth.signOut();
    final error = response.error;
    if (error != null) {
      context.showErrorSnackBar(message: error.message);
    }
    Navigator.of(context)
        .pushAndRemoveUntil(SplashPage.route(), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      children: [
        TextFormField(
          initialValue: widget.initialUserName,
          onChanged: (val) {
            userName = val;
          },
          decoration: const InputDecoration(labelText: 'User Name'),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: isLoading ? null : _updateProfile,
          child: const Text('Save'),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: isLoading ? null : _signOut,
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
