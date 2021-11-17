part of 'messages_cubit.dart';

@immutable
abstract class MessagesState {}

class MessagesInitial extends MessagesState {}

class MessagesLoaded extends MessagesState {
  MessagesLoaded(this.messages);
  final List<Message> messages;
}
