import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_model.dart';
import 'auth_service.dart';

// API service for chat operation
class ChatService {
  static const String baseUrl = 'https://wavelength-api.mercantec.tech';
  //static const _secureStorage = FlutterSecureStorage();
  static final _authService = AuthService();

  // Get chat room for a matched user by name
  static Future<ChatRoom> getChatRoomForUser(String userName) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      // Fetch user's chat rooms
      final response = await http.get(
        Uri.parse('$baseUrl/Chat/ListChatRooms'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      //print('DEBUG getChatRoomForUser - Status: ${response.statusCode}');
      //print('DEBUG getChatRoomForUser - Body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> rooms = jsonDecode(response.body);
        
        // Find room matching the user name
        for (var room in rooms) {
          final chatRoomName = room['chatRoomName'] ?? '';
          final chatRoomId = room['chatRoomId'] ?? '';
          
          //print('DEBUG Room: name=$chatRoomName, id=$chatRoomId');
          
          // Match by user name in room name
          if (chatRoomName.contains(userName) && chatRoomId.isNotEmpty) {
            //print('DEBUG Found matching room: $chatRoomName with ID: $chatRoomId');
            return ChatRoom(
              id: chatRoomId,
              name: chatRoomName,
              participants: [userName],
            );
          }
        }
        
        throw Exception('No chat room found for user: $userName');
      } else {
        throw Exception('Failed to fetch chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chat room: $e');
    }
  }

  // Remove notifications for a chat room
  static Future<void> removeNotifications(String chatRoomId) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/Chat/RemoveNotifications')
            .replace(queryParameters: {'chatRoomId': chatRoomId}),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      //print('DEBUG removeNotifications - Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to remove notifications: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error removing notifications: $e');
    }
  }

  // Get chat room details
  static Future<ChatRoom> getChatRoom(String chatRoomId) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/Chat/$chatRoomId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ChatRoom.fromJson(json);
      } else {
        throw Exception('Failed to get chat Room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chat room: $e');
    }
  }

  // Send a message in the chat room
  static Future<void> sendMessage(
    String chatRoomId,
    String messageContent
  ) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/Chat/message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'chatRoomId': chatRoomId,
          'messageContent': messageContent
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        //print('DEBUG sendMessage - Status: ${response.statusCode}');
        //print('DEBUG sendMessage - Body: ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Get messages from chat room with pagination
  static Future<ChatMessagesResponse> getMessages(
    String chatRoomId,
    String? cursor
  ) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/Chat/messages/getMessages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'chatRoomId': chatRoomId,
          if (cursor != null) 'cursor': cursor,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          // Return empty response if no messages
          return ChatMessagesResponse(
            messageObjects: [],
            nextCursor: null,
            hasMore: false,
          );
        }
        
        final json = jsonDecode(response.body);
        return ChatMessagesResponse.fromJson(json);
      } else {
        //print('DEBUG getMessages - Status: ${response.statusCode}');
        //print('DEBUG getMessages - Body: ${response.body}');
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting messages: $e');
    }
  }

  // Delete a message
  static Future<void> deleteMessage(int messageId) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('$baseUrl/Chat/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) throw Exception('Failed to delete message: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // Leave a chat room
  static Future<void> leaveChatRoom(String chatRoomId) async {
    try {
      final token = await _authService.getValidJwtToken();

      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('$baseUrl/Chat/leave/$chatRoomId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) throw Exception('Failed to leave chat room: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error leaving chat room: $e');
    }
  }
}
