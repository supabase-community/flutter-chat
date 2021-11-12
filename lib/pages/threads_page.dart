import 'package:flutter/material.dart';

/// Displays the past chat threads
class ThreadsPage extends StatelessWidget {
  const ThreadsPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) {
      return const ThreadsPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
    );
  }
}
