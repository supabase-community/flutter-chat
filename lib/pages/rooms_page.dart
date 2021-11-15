import 'package:flutter/material.dart';
import 'package:supabase_quickstart/models/room.dart';
import 'package:supabase_quickstart/utils/constants.dart';
import 'package:supabase_quickstart/utils/store.dart';

/// Displays the past chat threads
class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  static Route<void> route() {
    Store().getRooms();
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
      body: StreamBuilder<List<Room>>(
        stream: Store().roomStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.connectionState != ConnectionState.active) {
            return preloader;
          }
          final rooms = snapshot.data!;
          return ListView.builder(itemBuilder: (context, index) {
            final room = rooms[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(room.participants.first.name),
              ),
              title: Text(room.participants.first.name),
              subtitle: room.lastMessage != null
                  ? Text(room.lastMessage!.text)
                  : null,
            );
          });
        },
      ),
    );
  }
}
