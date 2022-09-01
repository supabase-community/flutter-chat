
import 'package:my_chat_app/pages/chat_page.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:my_chat_app/utils/messages_provider.dart';
// import 'package:rxdart/subjects.dart';

MessagesNotifierProvider messagesNotifierProvider = StateNotifierProvider<AsyncLoading><void>>((ref) {
  var resp = ref.read(messagesRepository);
});
class MessagesNotifierProvider extends StateNotifierProvider<List<Message>, AsyncValue<void>>((ref) {
  return 
} {
  // static final MessagesNotifierProvider _singleton = MessagesNotifierProvider._();

  factory MessagesProvider(T Function(Ref ref, AsyncValue<void>) builder) {
    return _singleton;1
  }

  // MessagesProvider._();
  final Map<String, StreamSubscription<List<Message>>> _messageSubscriptions = {};

  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  String? _myUserId;

  StreamSubscription<List<Message>> subscribe(String roomId) {
    _myUserId ??= supabase.auth.currentUser!.id;

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
                  myUserId: _myUserId!,
                ),
              )
              .toList(),
        ).when(
          loading: const CircularProgressIndicator(),
          data: null, 
          error: (error) {
            print(error);
        })
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

  Future<Room> createRoom(String userId ) {
    supabase.from("messages:room_id=eq.$userId").insert({
      'room_id': roomId,
      'profile_id': userId,Iso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().tooIso8601String(),
     },
    )
  };
}
)