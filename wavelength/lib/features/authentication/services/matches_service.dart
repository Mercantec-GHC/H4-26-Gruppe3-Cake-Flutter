import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/matched_user_model.dart';
import 'auth_service.dart';

class MatchesService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';
  //static const _secureStorage = FlutterSecureStorage();
  static final _authService = AuthService();


  // Fetch a page of matched users from the API.
  static Future<List<MatchedUser>> fetchMatchedUsers({
    required int page,
    required int count,
  }) async {
    try {
      final token = await _authService.getValidJwtToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/User/MatchedUsers').replace(
        queryParameters: {
          'count': count.toString(),
          'page': page.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body);
        if (jsonList is List) {
          return jsonList
              .map((item) => MatchedUser.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      }

      throw Exception('Failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Returns total number of pages for a given page size.
  static Future<int> fetchMatchesPageCount({
    required int pageCount,
  }) async {
    try {
      final token = await _authService.getValidJwtToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/User/MatchesCount').replace(
        queryParameters: {
          'pageCount': pageCount.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return int.tryParse(response.body.trim()) ?? 0;
      }

      throw Exception('Failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static String getAvatarUrl(String userId) {
    return '$baseUrl/Images/Avatar/$userId';
  }
}
