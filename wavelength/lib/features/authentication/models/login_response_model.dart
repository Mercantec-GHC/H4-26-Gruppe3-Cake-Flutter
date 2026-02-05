class LoginResponseModel {
  final String jwtToken;
  final String refreshToken;
  final int expires;

  LoginResponseModel({
    required this.jwtToken,
    required this.refreshToken,
    required this.expires
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      jwtToken: json['jwtToken'] as String, 
      refreshToken: json['refreshToken'] as String, 
      expires: json['expires'] as int
    );
  }
}