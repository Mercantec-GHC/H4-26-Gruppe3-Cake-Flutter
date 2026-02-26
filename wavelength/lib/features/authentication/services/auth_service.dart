import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/register_model.dart';
import '../models/login_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _secureStorage = FlutterSecureStorage();
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';
  
  // Lock to prevent concurrent refresh attempts
  Future<String?>? _refreshInProgress;
  DateTime? _lastRefreshTime;

  Future<http.Response> register(RegisterModel user) async {
    try {
      final response = await http.post(
            Uri.parse('$baseUrl/Auth/register'),
            headers: {'Content-Type': 'application/json'},
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
            headers: {'Content-Type': 'application/json'},
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

  Future<http.Response> verifyEmail(String code) async {
    try {
      final response = await http.post(
            Uri.parse('$baseUrl/Auth/verifyEmail'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code}),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      return response;
    } catch (e) {
      throw Exception('Fejl ved emailverifikation: $e');
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

  Future<http.Response> me() async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      final response = await http.get(
            Uri.parse('$baseUrl/Auth/me'),
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
      throw Exception('Fejl ved hentning af brugerdata: $e');
    }
  }

  Future<http.Response> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      final body = jsonEncode({
        'CurrentPassword': currentPassword,
        'NewPassword': newPassword,
        'ConfirmNewPassword': confirmNewPassword,
      });

      //print('UpdatePassword Request Body: $body'); // Debug

      final response = await http.put(
            Uri.parse('$baseUrl/Auth/UpdatePassword'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      //print('UpdatePassword Response: ${response.statusCode} - ${response.body}',); // Debug

      return response;
    } catch (e) {
      throw Exception('Fejl ved ændring af adgangskode: $e');
    }
  }

  Future<http.Response> updateDescription(String description) async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      final response = await http.put(
            Uri.parse('$baseUrl/Auth/UpdateDescription'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'Description': description}),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      return response;
    } catch (e) {
      throw Exception('Fejl ved opdatering af beskrivelse: $e');
    }
  }

  Future<http.Response> uploadAvatar(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/Images/Avatar/Upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Determine content type based on file extension
      String contentType = 'image/jpeg';
      final lowerFileName = fileName.toLowerCase();
      if (lowerFileName.endsWith('.png')) {
        contentType = 'image/png';
      } else if (lowerFileName.endsWith('.jpg') ||
          lowerFileName.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (lowerFileName.endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (lowerFileName.endsWith('.webp')) {
        contentType = 'image/webp';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          contentType: http.MediaType.parse(contentType),
        ),
      );

      //print('Uploading avatar: $fileName with content-type: $contentType',); // Debug

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      //print('Upload Avatar Response: ${response.statusCode} - ${response.body}',); // Debug

      return response;
    } catch (e) {
      throw Exception('Fejl ved upload af profilbillede: $e');
    }
  }

  Future<Uint8List?> getAvatarImage() async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      final response = await http.get(
            Uri.parse('$baseUrl/Images/Avatar'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      //print('Fejl ved hentning af avatar: $e');
      return null;
    }
  }

  Future<String?> getValidJwtToken() async {
    final jwtToken = await _secureStorage.read(key: 'jwtToken');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    final jwtExpiry = await _secureStorage.read(key: 'jwtExpiry');

    if (jwtToken == null || refreshToken == null || jwtExpiry == null)
      return null;

    final expiry = DateTime.tryParse(jwtExpiry);
    if (expiry == null) {
      await clearTokens();
      return null;
    }

    final nowUtc = DateTime.now().toUtc();
    
    // Refresh mechanism is working correctly - disabled force refresh
    final forceRefresh = false;
    
    if (forceRefresh || nowUtc.isAfter(expiry)) {
      // If we just refreshed within the last 2 seconds, return the current token
      if (_lastRefreshTime != null && 
          nowUtc.difference(_lastRefreshTime!).inSeconds < 2) {
        return jwtToken;
      }
      
      // If a refresh is already in progress, wait for it
      if (_refreshInProgress != null) {
        return await _refreshInProgress;
      }
      
      // Start a new refresh and store it so concurrent calls can wait
      _refreshInProgress = _refreshJwtToken(refreshToken).then((newToken) {
        _refreshInProgress = null; // Clear the lock when done
        if (newToken != null) {
          _lastRefreshTime = DateTime.now().toUtc(); // Track successful refresh
        }
        return newToken;
      });
      
      final newJwtToken = await _refreshInProgress;
      if (newJwtToken == null) {
        await clearTokens();
        return null;
      }
      return newJwtToken;
    }

    return jwtToken;
  }

  Future<String?> _refreshJwtToken(String refreshToken) async {
    try {
      if (refreshToken.isEmpty) {
        return null;
      }

      final body = jsonEncode({'Token': refreshToken});

      final response = await http.post(
            Uri.parse('$baseUrl/Auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(response.body);

      final newJwtToken = json['jwtToken'] as String?;
      final newRefreshToken = (json['refreshToken'] as String?) ?? refreshToken;

      DateTime? newExpiry;
      final expiresValue = json['expires'] as int;
      newExpiry = DateTime.now().toUtc().add(Duration(seconds: expiresValue));

      if (newJwtToken == null) return null;

      await _secureStorage.write(key: 'jwtToken', value: newJwtToken);
      await _secureStorage.write(key: 'refreshToken', value: newRefreshToken);
      await _secureStorage.write(key: 'jwtExpiry', value: newExpiry.toString());

      return newJwtToken;
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> getAllTags() async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      final response = await http.post(
            Uri.parse('$baseUrl/User/AllTags'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      return response;
    } catch (e) {
      throw Exception('Fejl ved hentning af tags: $e');
    }
  }

  Future<http.Response> setUserTags(List<String> tags) async {
    try {
      final token = await getValidJwtToken();

      if (token == null) {
        throw Exception('Ingen gyldig token fundet');
      }

      final response = await http.put(
            Uri.parse('$baseUrl/User/SetTags'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(tags),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      return response;
    } catch (e) {
      throw Exception('Fejl ved gemning af tags: $e');
    }
  }

  Future<http.Response> editQuiz(Map<String, dynamic> quizData) async {
    try {
      final token = await getValidJwtToken();
      if (token == null) throw Exception('Ingen gyldig token fundet');

      final response = await http.post(
            Uri.parse('$baseUrl/Quiz/EditQuiz'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(quizData),
          )
          .timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      throw Exception('Fejl ved opdatering af quiz: $e');
    }
  }

  Future<http.Response> getQuiz() async {
    try {
      final token = await getValidJwtToken();
      if (token == null) throw Exception('Ingen gyldig token fundet');

      final response = await http.get(
            Uri.parse('$baseUrl/Quiz/MyQuiz'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      throw Exception('Fejl ved hentning af quiz: $e');
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'jwtToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'jwtExpiry');
  }
}
