import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/discover_model.dart';

class DiscoverService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';
  static const _secureStorage = FlutterSecureStorage();

  static Future<DiscoverUser> fetchDiscoverUser({String? userId}) async {
    try {
      final token = await _secureStorage.read(key: 'jwtToken');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint = userId != null ? '$baseUrl/User/$userId' : '$baseUrl/User/Discover';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('API Response: $json');
        print('Available keys: ${json.keys}');
        return DiscoverUser.fromJson(json);
      } else {
        throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static String getInterestImageUrl(int interestId, {bool miniature = true}) {
    return '$baseUrl/Images/Interest/$interestId?miniature=$miniature';
  }
}
