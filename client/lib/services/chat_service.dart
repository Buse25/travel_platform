import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api/chats";
    }
    return "http://10.0.2.2:5000/api/chats";
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  static Future<Map<String, dynamic>?> getOrCreateConversation(
    String userId,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception("Oturum bulunamadi.");

    final response = await http
        .post(
          Uri.parse("$baseUrl/conversation/$userId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["conversation"];
    }

    throw Exception(data["message"] ?? "Konusma baslatilamadi.");
  }

  static Future<List<dynamic>> getConversations() async {
    final token = await _getToken();
    if (token == null) throw Exception("Oturum bulunamadi.");

    final response = await http
        .get(
          Uri.parse("$baseUrl/conversations"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["conversations"] ?? [];
    }

    throw Exception(data["message"] ?? "Konusmalar alinamadi.");
  }

  static Future<int> getUnreadCount() async {
    final token = await _getToken();
    if (token == null) return 0;

    final response = await http
        .get(
          Uri.parse("$baseUrl/unread-count"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["unreadCount"] ?? 0;
    }

    return 0;
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Oturum bulunamadi.");

    final response = await http
        .get(
          Uri.parse("$baseUrl/messages/$conversationId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["messages"] ?? [];
    }

    throw Exception(data["message"] ?? "Mesajlar alinamadi.");
  }

  static Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Oturum bulunamadi.");

    final response = await http
        .post(
          Uri.parse("$baseUrl/messages/$conversationId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"text": text}),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data["message"];
    }

    throw Exception(data["message"] ?? "Mesaj gonderilemedi.");
  }

  static Future<void> markConversationAsRead(String conversationId) async {
    final token = await _getToken();
    if (token == null) return;

    await http
        .put(
          Uri.parse("$baseUrl/messages/$conversationId/read"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));
  }
}
