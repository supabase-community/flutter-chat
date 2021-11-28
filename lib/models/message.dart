class Message {
  Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String userId;
  final String roomId;
  final String text;
  final DateTime createdAt;

  /// Whether the message is sent by the user or not.
  final bool isMine;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'text': text,
    };
  }

  static Message fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  }) {
    return Message(
      id: map['id'],
      roomId: map['room_id'],
      userId: map['user_id'],
      text: map['text'],
      createdAt: DateTime.parse(map['created_at']),
      isMine: myUserId == map['user_id'],
    );
  }

  Message copyWith({
    String? id,
    String? userId,
    String? roomId,
    String? text,
    DateTime? createdAt,
    bool? isMine,
  }) {
    return Message(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
    );
  }
}
