class Profile({
  /// User ID of the profile
  required final String id,

  /// Username of the profile
  required final String username,

  /// Date and time when the profile was created
  required final DateTime createdAt,
}) {
  new fromMap(Map<String, dynamic> map)
    : this(
        id: map['id'],
        username: map['username'],
        createdAt: DateTime.parse(map['created_at']),
      );
}
