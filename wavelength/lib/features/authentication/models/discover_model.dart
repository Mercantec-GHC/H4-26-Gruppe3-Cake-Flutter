class DiscoverUser {
  final String id;
  final String firstName;
  final String lastName;
  final String description;
  final List<int> interests;
  final List<String> tags;

  DiscoverUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.interests,
    required this.tags,
  });

  factory DiscoverUser.fromJson(Map<String, dynamic> json) {
    print('=== JSON Data Received ===');
    print('Full JSON: $json');
    print('All keys in response: ${json.keys.toList()}');
    
    final interests = List<int>.from(json['interests'] ?? json['pictures'] ?? []);
    print('Parsed interests: $interests');
    print('Interests count: ${interests.length}');
    
    return DiscoverUser(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      description: json['description'] ?? '',
      interests: interests,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
