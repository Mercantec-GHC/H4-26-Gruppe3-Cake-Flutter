class UserModel {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime? birthday;
  final DateTime? createdAt;
  final String? description;
  final List<String>? tags;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.birthday,
    this.createdAt,
    this.description,
    this.tags,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? json['userName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      birthday: json['birthday'] != null 
          ? DateTime.tryParse(json['birthday'].toString())
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      description: json['description']?.toString(),
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : null,
      profilePicture: json['profilePicture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'description': description,
      'tags': tags,
      'profilePicture': profilePicture,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? birthday,
    DateTime? createdAt,
    String? description,
    List<String>? tags,
    String? profilePicture,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
