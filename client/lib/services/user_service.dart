import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api/users";
    }
    return "http://10.0.2.2:5000/api/users";
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      print('[UserService] baseUrl: $baseUrl');
      print(
        '[UserService] token: ${token != null ? "VAR (${token.length} karakter)" : "YOK"}',
      );

      if (token == null) return null;

      final uri = Uri.parse("$baseUrl/me");
      final response = await http
          .get(
            uri,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      print('[UserService] getUserProfile status: ${response.statusCode}');
      print('[UserService] getUserProfile body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["user"];
      } else if (response.statusCode == 401) {
        await prefs.remove('jwt_token');
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print('[UserService] getUserProfile error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getSuggestedUsers() async {
    try {
      print('[UserService] getSuggestedUsers URL: $baseUrl/suggested');

      final response = await http
          .get(Uri.parse("$baseUrl/suggested"))
          .timeout(const Duration(seconds: 10));

      print('[UserService] getSuggestedUsers status: ${response.statusCode}');
      print('[UserService] getSuggestedUsers body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["users"] ?? [];
      }
      return [];
    } catch (e) {
      print('[UserService] getSuggestedUsers error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = "$baseUrl/search?q=$encodedQuery";

      print('[UserService] searchUsers URL: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print('[UserService] searchUsers status: ${response.statusCode}');
      print('[UserService] searchUsers body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["users"] ?? [];
      }
      return [];
    } catch (e) {
      print('[UserService] searchUsers error: $e');
      return [];
    }
  }
}
