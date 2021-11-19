import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_quickstart/cubits/messages/messages_cubit.dart';
import 'package:supabase_quickstart/utils/constants.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  static Route<void> route(String roomId) {
    return MaterialPageRoute(
      builder: (context) => BlocProvider<MessagesCubit>(
        create: (context) => MessagesCubit()..setMessagesListener(roomId),
        child: const ChatPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: BlocBuilder<MessagesCubit, MessagesState>(
        builder: (context, state) {
          if (state is MessagesInitial) {
            return preloader;
          } else if (state is MessagesLoaded) {
            final messages = state.messages;
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Text(message.text),
                );
              },
            );
          }
          throw UnimplementedError();
        },
      ),
    );
  }
}
