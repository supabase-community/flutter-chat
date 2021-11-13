import 'package:flutter/material.dart';

/// Displays the past chat threads
class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) {
      return const RoomsPage();
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
