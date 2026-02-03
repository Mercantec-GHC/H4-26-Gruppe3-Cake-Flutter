import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/register_model.dart';

class AuthService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';

  Future<http.Response> register(RegisterModel user) async {
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
}
