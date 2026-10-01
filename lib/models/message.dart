class Message({
  /// ID of the message
  required final String id,

  /// ID of the user who posted the message
  required final String profileId,

  /// Text content of the message
  required final String content,

  /// Date and time when the message was created
  required final DateTime createdAt,

  /// Whether the message is sent by the user or not.
  required final bool isMine,
}) {
  new fromMap({required Map<String, dynamic> map, required String myUserId})
    : this(
        id: map['id'],
        profileId: map['profile_id'],
        content: map['content'],
        createdAt: DateTime.parse(map['created_at']),
        isMine: myUserId == map['profile_id'],
      );
}
