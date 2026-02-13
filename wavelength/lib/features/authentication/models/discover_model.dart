class DiscoverUser {
  final String id;
  final String firstName;
  final String lastName;
  final String description;
  final List<int> pictures;
  final List<String> tags;

  DiscoverUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.pictures,
    required this.tags,
  });

  factory DiscoverUser.fromJson(Map<String, dynamic> json) {
    return DiscoverUser(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      description: json['description'] ?? '',
      pictures: List<int>.from(json['pictures'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
