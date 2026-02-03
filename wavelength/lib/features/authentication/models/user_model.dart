class UserModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final DateTime birthday;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.birthday,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'birthday': birthday.toIso8601String().split('T')[0],
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    DateTime? birthday,
  }) {
    return UserModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      birthday: birthday ?? this.birthday,
    );
  }

  @override
  String toString() {
    return 'UserModel(firstName: $firstName, lastName: $lastName, email: $email, password: $password, birthday: $birthday)';
  }
}
