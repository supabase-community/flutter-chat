import 'package:supabase_quickstart/models/app_user.dart';

class Room {
  Room({
    required this.id,
    required this.createdAt,
    required this.participants,
  });

  final String id;
  final DateTime createdAt;
  final List<AppUser> participants;
}
