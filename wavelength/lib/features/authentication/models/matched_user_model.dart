class MatchedUser {
  final String id;
  final String firstName;
  final String lastName;
  // MatchPercent can be null; only display when present.
  final int? matchPercent;
  final List<String> tags;

  MatchedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.matchPercent,
    required this.tags,
  });

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? firstName : combined;
  }

  factory MatchedUser.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'];
    final matchValue = json['matchPercent'];

    return MatchedUser(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      matchPercent: matchValue == null ? null : (matchValue as num).toInt(),
      tags: tagsJson is List
          ? tagsJson.map((tag) => tag.toString()).toList()
          : <String>[],
    );
  }
}
