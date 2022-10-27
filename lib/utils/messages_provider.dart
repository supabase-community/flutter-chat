import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/utils/constants.dart';

class MessagesProvider {
  static final MessagesProvider _singleton = MessagesProvider._();

  factory MessagesProvider() {
    return _singleton;
  }

  MessagesProvider._();

  final Map<String, StreamSubscription<List<Message>>> _messageSubscriptions =
      {};

  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  String? _myUserId;

  Stream<List<Message>> subscribe(String roomId) {
    _myUserId ??= supabase.auth.currentUser?.id;

    _messageControllers[roomId] ??= BehaviorSubject();

    _messageSubscriptions[roomId] ??= supabase
        .from('messages:room_id=eq.$roomId')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map<List<Message>>(
          (data) => data
              .map<Message>(
                (row) => Message.fromMap(
                  map: row,
                  myUserId: _myUserId!,
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
  }
}
