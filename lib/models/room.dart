import 'dart:convert';

import 'package:supabase_quickstart/models/app_user.dart';

class Room {
  Room({
    required this.id,
    required this.createdAt,
    required this.participants,
  });

  final String id;
  final DateTime createdAt;
  final List<AppUser> participants;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'participants': participants.map((x) => x.toMap()).toList(),
    };
  }

  static Room fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      participants: List<AppUser>.from(
          map['participants']?.map((x) => AppUser.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Room.fromJson(String source) => Room.fromMap(json.decode(source));
}
