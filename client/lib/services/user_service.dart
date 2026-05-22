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
      return null;
    }
  }

  static Future<List<dynamic>> getSuggestedUsers() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/suggested"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["users"] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = "$baseUrl/search?q=$encodedQuery";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["users"] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String city,
    String? profileImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {
          "success": false,
          "message": "Oturum bulunamadı. Lütfen tekrar giriş yap.",
        };
      }

      final response = await http
          .put(
            Uri.parse("$baseUrl/me"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "fullName": fullName,
              "username": username,
              "email": email,
              "phone": phone,
              "city": city,
              "profileImage": profileImage,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Profil güncellendi.",
          "user": data["user"],
        };
      }

      return {
        "success": false,
        "message": data["message"] ?? "Profil güncellenemedi.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Profil güncellenirken hata oluştu.",
      };
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {
          "success": false,
          "message": "Oturum bulunamadı. Lütfen tekrar giriş yap.",
        };
      }

      final response = await http
          .put(
            Uri.parse("$baseUrl/change-password"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "oldPassword": oldPassword,
              "newPassword": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Şifre değiştirildi.",
        };
      }

      return {
        "success": false,
        "message": data["message"] ?? "Şifre değiştirilemedi.",
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Şifre değiştirilirken hata oluştu.",
      };
    }
  }
}
