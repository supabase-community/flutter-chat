import 'dart:convert';

class Message {
  Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String roomId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'roomId': roomId,
      'text': text,
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
    String? userId,
    String? roomId,
    String? text,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
