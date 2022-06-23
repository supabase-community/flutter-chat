class Message {
  Message({
    required this.id,
    required this.roomId,
    required this.profileId,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String profileId;
  final String roomId;
  final String content;
  final DateTime createdAt;

  /// Whether the message is sent by the user or not.
  final bool isMine;

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'room_id': roomId,
      'content': content,
    };
  }

  static Message fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  }) {
    return Message(
      id: map['id'],
      roomId: map['room_id'],
      profileId: map['profile_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      isMine: myUserId == map['profile_id'],
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
      profileId: userId ?? profileId,
      roomId: roomId ?? this.roomId,
      content: text ?? content,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
    );
  }
}
