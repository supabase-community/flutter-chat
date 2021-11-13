class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
}
