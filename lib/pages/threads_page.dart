import 'package:flutter/material.dart';

/// Displays the past chat threads
class ThreadsPage extends StatelessWidget {
  static const route = '/threads';
  const ThreadsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
    );
  }
}
