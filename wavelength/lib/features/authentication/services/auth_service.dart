import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/register_model.dart';
import '../models/login_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _secureStorage = FlutterSecureStorage();
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

  Future<http.Response> logout(String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    return response;
    } catch (e) {
      throw Exception('Fejl ved logout: $e');
    }
  }

  Future<String?> getValidJwtToken() async {
    final jwtToken = await _secureStorage.read(key: 'jwtToken');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    final jwtExpiry = await _secureStorage.read(key: 'jwtExpiry');

    if (jwtToken == null || refreshToken == null || jwtExpiry == null) return null;

    final expiry = DateTime.tryParse(jwtExpiry);
    if (expiry == null) {
      await clearTokens();
      return null;
    }

    final nowUtc = DateTime.now().toUtc();
    if (nowUtc.isAfter(expiry)) {
      final refreshed = await _refreshJwtToken(refreshToken);
      if (!refreshed) {
        await clearTokens();
        return null;
      }
    }

    return jwtToken;
  }

  Future<bool> _refreshJwtToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode != 200) {
        return false;
      }

      final Map<String, dynamic> json = jsonDecode(response.body);

      final newJwtToken = json['jwtToken'] as String?;
      final newRefreshToken = (json['refreshToken'] as String?) ?? refreshToken;

      DateTime? newExpiry;
      final expiresValue = json['expires'] as int;
      newExpiry = DateTime.now().toUtc().add(Duration(seconds: expiresValue));

      if (newJwtToken == null) return false;

      await _secureStorage.write(key: 'jwtToken', value: newJwtToken);
      await _secureStorage.write(key: 'refreshToken', value: newRefreshToken);
      await _secureStorage.write(key: 'jwtExpiry', value: newExpiry.toString());

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'jwtToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'jwtExpiry');
  }
}
