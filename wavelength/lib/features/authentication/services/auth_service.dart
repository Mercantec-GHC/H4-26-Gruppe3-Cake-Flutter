import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/login_model.dart';

class AuthService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';

  Future<http.Response> register(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      return response;
    } catch (e) {
      throw Exception('Fejl ved registrering: $e');
    }
  }

  Future<http.Response> login(LoginModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      return response;
    } catch (e) {
      throw Exception('Fejl ved login: $e');
    }
  }
}
