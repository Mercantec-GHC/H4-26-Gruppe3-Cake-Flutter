import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import 'auth_service.dart';

/// API service for quiz operations
class QuizService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';
  //static const _secureStorage = FlutterSecureStorage();
  static final _authService = AuthService();

  /// Fetch quiz questions from API with JWT authentication
  static Future<List<QuizQuestion>> fetchUserQuiz(String userId) async {
    try {
      final token = await _authService.getValidJwtToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/quiz/UserQuiz/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((q) => QuizQuestion.fromJson(q)).toList();
      } else {
        throw Exception('Failed to load quiz: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching quiz: $e');
    }
  }

  /// Submit user's answers to API and receive match percentage and pass status
  static Future<QuizResult> submitQuizAnswers(
    String userId,
    List<int> answerIndices,
  ) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/Quiz/SubmitQuiz'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'answers': answerIndices,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return QuizResult.fromJson(json);
      } else {
        throw Exception('Failed to submit quiz: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting quiz: $e');
    }
  }
}
