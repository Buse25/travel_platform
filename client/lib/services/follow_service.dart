import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FollowService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api/follows";
    }
    return "http://10.0.2.2:5000/api/follows";
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  static Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          "success": false,
          "message": "Oturum bulunamadi. Lutfen tekrar giris yap.",
        };
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/$userId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          "success": true,
          "message": data["message"] ?? "Kullanici takip edildi.",
          "follow": data["follow"],
        };
      }

      return {
        "success": false,
        "message": data["message"] ?? "Takip islemi basarisiz.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Takip islemi sirasinda hata olustu.",
      };
    }
  }

  static Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          "success": false,
          "message": "Oturum bulunamadi. Lutfen tekrar giris yap.",
        };
      }

      final response = await http
          .delete(
            Uri.parse("$baseUrl/$userId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Kullanici takipten cikarildi.",
        };
      }

      return {
        "success": false,
        "message": data["message"] ?? "Takipten cikarma basarisiz.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Takipten cikarma sirasinda hata olustu.",
      };
    }
  }

  static Future<Map<String, int>> getFollowStats(String userId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/stats/$userId"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "followersCount": data["followersCount"] ?? 0,
          "followingCount": data["followingCount"] ?? 0,
        };
      }

      return {
        "followersCount": 0,
        "followingCount": 0,
      };
    } catch (e) {
      return {
        "followersCount": 0,
        "followingCount": 0,
      };
    }
  }

  static Future<bool> isFollowing(String userId) async {
    try {
      final token = await _getToken();

      if (token == null) return false;

      final response = await http
          .get(
            Uri.parse("$baseUrl/is-following/$userId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["isFollowing"] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
