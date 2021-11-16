import 'dart:convert';

import 'package:supabase_quickstart/models/app_user.dart';

class Message {
  Message({
    required this.id,
    this.user,
    required this.roomId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final AppUser? user;
  final String userId;
  final String roomId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': user?.toMap(),
      'user_id': userId,
      'roomId': roomId,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      roomId: map['room_id'],
      userId: map['user_id'],
      text: map['text'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source));

  Message copyWith({
    String? id,
    AppUser? user,
    String? userId,
    String? roomId,
    String? text,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
