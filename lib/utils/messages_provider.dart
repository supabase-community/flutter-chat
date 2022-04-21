import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:supabase_chat/models/message.dart';
import 'package:supabase_chat/utils/constants.dart';

class MessagesProvider {
  static final MessagesProvider _singleton = MessagesProvider._();

  factory MessagesProvider() {
    return _singleton;
  }

  MessagesProvider._();

  final Map<String, StreamSubscription<List<Message>>> _messageSubscriptions =
      {};
  final Map<String, List<Message>> _messages = {};
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  String? _userId;

  Stream<List<Message>> subscribe(String roomId) {
    _userId ??= supabase.auth.user()!.id;

    _messageControllers[roomId] ??= BehaviorSubject();

    _messageSubscriptions[roomId] ??= supabase
        .from('messages:room_id=eq.$roomId')
        .stream(['id'])
        .order('created_at')
        .execute()
        .map<List<Message>>(
          (data) => data
              .map<Message>(
                (row) => Message.fromMap(
                  map: row,
                  myUserId: _userId!,
                ),
              )
              .toList(),
        )
        .listen((messages) {
          _messageControllers[roomId]!.add(messages);
        });

    return _messageControllers[roomId]!.stream;
  }

  void clear() {
    for (final listener in _messageSubscriptions.values) {
      listener.cancel();
    }
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messages.clear();
  }
}
