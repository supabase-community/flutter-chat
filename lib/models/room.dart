import 'package:supabase_chat/models/message.dart';

class Room {
  Room({
    required this.id,
    required this.createdAt,
    required this.opponentUserId,
    this.lastMessage,
  });

  final String id;
  final DateTime createdAt;
  final String opponentUserId;
  final Message? lastMessage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a room object from room_participants table
  static Room fromRoomParticipants(Map<String, dynamic> map) {
    return Room(
      id: map['room_id'],
      opponentUserId: map['profile_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Room copyWith({
    String? id,
    DateTime? createdAt,
    String? opponentUserId,
    Message? lastMessage,
  }) {
    return Room(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      opponentUserId: opponentUserId ?? this.opponentUserId,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
