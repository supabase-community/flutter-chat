// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';

import 'package:my_chat_app/cubits/profiles/profiles_cubit.dart';
import 'package:my_chat_app/cubits/rooms/rooms_cubit.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/pages/chat_page.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:my_chat_app/utils/messages_provider.dart';

final roomsControllerProvider = Provider<List<Message>>((ref) {});

final repo = Provider<RoomsRepository>((ref) => RoomsRepository(ref));

/// Displays the list of chat threads
class RoomsPage extends StatelessWidget {
  final Ref ref;
  RoomsRepository roomsRepository;
  RoomsPage({
    Key? key,
    required this.ref,
    required this.roomsRepository,
  }) : super(key: key);

  Route<void> route() {
    ref.read(repo);
    return MaterialPageRoute(
      builder: (context) => BlocProvider<RoomCubit>(
        create: (context) => RoomCubit(messagesProvider: messageProvider)..initializeRooms(context),
        child: const RoomsPage(
          ref: ref,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
      ),
      body: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          if (state is RoomsLoading) {
            return preloader;
          } else if (state is RoomsLoaded) {
            final newUsers = state.newUsers;
            final rooms = state.rooms;
            return BlocBuilder<ProfilesCubit, ProfilesState>(
              builder: (context, state) {
                if (state is ProfilesLoaded) {
                  final profiles = state.profiles;
                  return Column(
                    children: [
                      _NewUsers(newUsers: newUsers),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final otherUser = profiles[room.otherUserId];

                            return ListTile(
                              onTap: () => Navigator.of(context).push(ChatPage.route(room.id)),
                              leading: CircleAvatar(
                                child: otherUser == null ? preloader : Text(otherUser.username.substring(0, 2)),
                              ),
                              title: Text(otherUser == null ? 'Loading...' : otherUser.username),
                              subtitle: room.lastMessage != null
                                  ? Text(
                                      room.lastMessage!.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const Text('Room created'),
                              trailing: Text(format(room.lastMessage?.createdAt ?? room.createdAt, locale: 'en_short')),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return preloader;
                }
              },
            );
          } else if (state is RoomsEmpty) {
            final newUsers = state.newUsers;
            return Column(
              children: [
                _NewUsers(newUsers: newUsers),
                const Expanded(
                  child: Center(
                    child: Text('Start a chat by tapping on available users'),
                  ),
                ),
              ],
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

class _NewUsers extends StatelessWidget {
  const _NewUsers({
    Key? key,
    required this.newUsers,
  }) : super(key: key);

  final List<Profile> newUsers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: newUsers
            .map<Widget>((user) => InkWell(
                  onTap: () async {
                    try {
                      final roomId = await BlocProvider.of<RoomCubit>(context).createRoom(user.id);
                      Navigator.of(context).push(ChatPage.route(roomId));
                    } catch (_) {
                      context.showErrorSnackBar(message: 'Failed creating a new room');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 60,
                      child: Column(
                        children: [
                          CircleAvatar(
                            child: Text(user.username.substring(0, 2)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
