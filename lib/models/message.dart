const _imageExtensions = {'gif', 'jpeg', 'jpg', 'png', 'webp'};

class Message({
  /// ID of the message
  required final String id,

  /// ID of the user who posted the message
  required final String profileId,

  /// Text content of the message
  required final String content,

  /// Path of the attached file in the attachments bucket
  required final String? attachmentPath,

  /// Original file name of the attached file
  required final String? attachmentName,

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
        attachmentPath: map['attachment_path'],
        attachmentName: map['attachment_name'],
        createdAt: DateTime.parse(map['created_at']),
        isMine: myUserId == map['profile_id'],
      );

  /// Whether the attached file can be shown as an image
  bool get hasImageAttachment =>
      _imageExtensions.contains(attachmentPath?.split('.').last.toLowerCase());
}
