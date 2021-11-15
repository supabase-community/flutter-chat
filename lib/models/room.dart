import 'dart:convert';

import 'package:supabase_quickstart/models/app_user.dart';
import 'package:supabase_quickstart/models/message.dart';

class Room {
  Room({
    required this.id,
    required this.createdAt,
    required this.participants,
    this.lastMessage,
  });

  final String id;
  final DateTime createdAt;
  final List<AppUser> participants;
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      participants: [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Room.fromJson(String source) => Room.fromMap(json.decode(source));

  Room copyWith({
    String? id,
    DateTime? createdAt,
    List<AppUser>? participants,
    Message? lastMessage,
  }) {
    return Room(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
