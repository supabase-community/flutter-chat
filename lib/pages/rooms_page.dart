import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_quickstart/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_quickstart/cubits/rooms/rooms_cubit.dart';
import 'package:supabase_quickstart/pages/chat_page.dart';
import 'package:supabase_quickstart/utils/constants.dart';

/// Displays the past chat threads
class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          if (state is RoomsInitial) {
            return preloader;
          } else if (state is RoomsLoaded) {
            final rooms = state.rooms;
            return BlocBuilder<AppUserCubit, AppUserState>(
              builder: (context, state) {
                if (state is AppUserLoaded) {
                  final appUsers = state.appUsers;
                  return ListView.builder(itemBuilder: (context, index) {
                    final room = rooms[index];
                    final opponent = appUsers[room.opponentUserId];

                    return ListTile(
                      onTap: () =>
                          Navigator.of(context).push(ChatPage.route(room.id)),
                      leading: CircleAvatar(
                        child:
                            opponent == null ? preloader : Text(opponent.name),
                      ),
                      title: opponent == null ? null : Text(opponent.name),
                      subtitle: room.lastMessage != null
                          ? Text(room.lastMessage!.text)
                          : null,
                    );
                  });
                } else {
                  return preloader;
                }
              },
            );
          } else if (state is RoomsError) {
            return Center(child: Text(state.message));
          }
          throw UnimplementedError();
        },
      ),
    );
  }
}
