import 'dart:convert';

import 'package:supabase_quickstart/models/message.dart';

class Room {
  Room({
    required this.id,
    required this.createdAt,
    this.opponentUserId,
    this.lastMessage,
  });

  final String id;
  final DateTime createdAt;
  final String? opponentUserId;
  final Message? lastMessage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static Room fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Room.fromJson(String source) => Room.fromMap(json.decode(source));

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
