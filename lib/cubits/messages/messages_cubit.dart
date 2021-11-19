import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase_quickstart/models/message.dart';
import 'package:supabase_quickstart/utils/constants.dart';

part 'messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit() : super(MessagesInitial());

  StreamSubscription<List<Message>>? _messagesSubscription;

  void setMessagesListener(String roomId) {
    _messagesSubscription = supabase
        .from('messages:room_id=eq.$roomId')
        .stream()
        .order('created_at')
        .execute()
        .map((data) => data.map(Message.fromMap).toList())
        .listen((messages) {
      emit(MessagesLoaded(messages));
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
