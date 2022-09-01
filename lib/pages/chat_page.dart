// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart';

import 'package:my_chat_app/components/user_avatar.dart';
import 'package:my_chat_app/cubits/messages/messages_cubit.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:my_chat_app/utils/messages_provider.dart';

final messagesProvider = MessagesProvider<List<Message>>((ref) {
  return ref.read(messagesRepository);
});
  // option 2
final repo = Provider<Repo>((ref) => Repo(ref));


  var messagesRepository;
  return ref.read(messagesRepository);
};


/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.
class ChatPage extends StatelessWidget {
  final Ref ref;
  
  


    ChatPage({
    Key? key,
    required this.ref,
    required this.MessagesProvider,
  }) : super(key: key);

   Route<void> route(String roomId) {
    
    return MaterialPageRoute(
      builder: (context) => BlocProvider<MessagesCubit>(
        create: (context) => MessagesCubit(messagesProvider: messagesProvider)..setMessagesListener(roomId),
        child:  ChatPage(
          ref: ref,
          MessagesProvider: null,
        ),
      ),
    );
    
      @override
      Widget build(BuildContext context) {
        // TODO: implement build
        
      }
   }
   
     @override
     Widget build(BuildContext context) {
    // TODO: implement build
 
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: BlocConsumer<MessagesCubit, MessagesState>(
        listener: (context, state) {
          if (state is MessagesError) {
            context.showErrorSnackBar(message: state.message);
          }
        },
        builder: (context, state) {
          if (state is MessagesInitial) {
            return preloader;
          } else if (state is MessagesLoaded) {
            final messages = state.messages;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
                ),
                const _MessageBar(),
              ],
            );
          } else if (state is MessagesEmpty) {
            return Column(
              children: const [
                Expanded(
                  child: Center(
                    child: Text('Start your conversation now :)'),
                  ),
                ),
                _MessageBar(),
              ],
            );
          } else if (state is MessagesError) {
            return Center(child: Text(state.message));
          }
          throw UnimplementedError();
        },
      ),
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  const _MessageBar({
    Key? key,
  }) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.text,
                maxLines: null,
                autofocus: true,
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _submitMessage(),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    BlocProvider.of<MessagesCubit>(context).sendMessage(text);
    _textController.clear();
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  final Message message;

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine) UserAvatar(userId: message.profileId),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: message.isMine ? Colors.black : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(message.content),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    state = AsyncValue.data(chatContents);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment: message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}
