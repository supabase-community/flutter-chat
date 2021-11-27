import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_quickstart/cubits/app_user/app_user_cubit.dart';
import 'package:supabase_quickstart/cubits/rooms/rooms_cubit.dart';
import 'package:supabase_quickstart/pages/account_page.dart';
import 'package:supabase_quickstart/pages/chat_page.dart';
import 'package:supabase_quickstart/utils/constants.dart';

/// Displays the past chat threads
class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => BlocProvider<RoomCubit>(
        create: (context) => RoomCubit(),
        child: const RoomsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(AccountPage.route()),
            icon: const Icon(Icons.person_outline_outlined),
          ),
        ],
      ),
      body: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          if (state is RoomsLoading) {
            return preloader;
          } else if (state is RoomsLoaded) {
            final newUsers = state.newUsers;
            final rooms = state.rooms;
            return BlocBuilder<AppUserCubit, AppUserState>(
              builder: (context, state) {
                if (state is AppUserLoaded) {
                  final appUsers = state.appUsers;
                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: newUsers
                              .map<Widget>((user) => InkWell(
                                    onTap: () async {
                                      final roomId =
                                          await BlocProvider.of<RoomCubit>(
                                                  context)
                                              .createRoom(user.id);
                                      Navigator.of(context)
                                          .push(ChatPage.route(roomId));
                                    },
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          child: Text(user.name),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(user.name),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(itemBuilder: (context, index) {
                          final room = rooms[index];
                          final opponent = appUsers[room.opponentUserId];

                          return ListTile(
                            onTap: () => Navigator.of(context)
                                .push(ChatPage.route(room.id)),
                            leading: CircleAvatar(
                              child: opponent == null
                                  ? preloader
                                  : Text(opponent.name),
                            ),
                            title:
                                opponent == null ? null : Text(opponent.name),
                            subtitle: room.lastMessage != null
                                ? Text(room.lastMessage!.text)
                                : null,
                          );
                        }),
                      ),
                    ],
                  );
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
