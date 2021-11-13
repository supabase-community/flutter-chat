import 'package:supabase_quickstart/models/app_user.dart';

class Message {
  Message({
    required this.id,
    required this.user,
    required this.roomId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final AppUser user;
  final String roomId;
  final String text;
  final DateTime createdAt;
}
