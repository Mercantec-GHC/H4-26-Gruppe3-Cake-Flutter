import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/discover_model.dart';
import 'auth_service.dart';

class DiscoverService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';
  //static const _secureStorage = FlutterSecureStorage();
  static final _authService = AuthService();

  static Future<DiscoverUser> fetchDiscoverUser() async {
    try {
      final token = await _authService.getValidJwtToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // POST to /User/Discover with empty exclusion list
      final response = await http.post(
        Uri.parse('$baseUrl/User/Discover'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode([]),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        //print('Discover Response: $json');
        return DiscoverUser.fromJson(json);
      } else {
        throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static String getInterestImageUrl(int imageId, {bool miniature = true}) {
    return '$baseUrl/Images/Interest/$imageId?miniature=$miniature';
  }

  static String getAvatarUrl(String userId) {
    return '$baseUrl/Images/Avatar/$userId';
  }

  static Future<void> dismissUser(String targetId) async {
    try {
      final token = await _authService.getValidJwtToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/UserVisibility/Dismissed?targetId=$targetId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      //print('Dismiss Response: Status ${response.statusCode}');
      //print('Dismiss Response Body: ${response.body}');

      // if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      //   print('Error dismissing user: ${response.statusCode} - ${response.body}');
      // } else {
      //   print('User successfully dismissed: $targetId');
      // }
    } catch (e) {
      // ignore: avoid_print
      print('Error dismissing user: $e');
    }
  }
}
