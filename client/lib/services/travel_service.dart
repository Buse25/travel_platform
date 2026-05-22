import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TravelService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api/travels";
    }
    return "http://10.0.2.2:5000/api/travels";
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  Future<Map<String, dynamic>> createTravel({
    required String country,
    required String city,
    required String district,
    required String startDate,
    required String endDate,
    required String purpose,
    required String category,
    required String description,
    String ticketPhoto = "",
    String locationPhoto = "",
  }) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
    }

    final body = {
      "country": country,
      "city": city,
      "district": district,
      "startDate": startDate,
      "endDate": endDate,
      "purpose": purpose,
      "category": category,
      "description": description,
      "ticketPhoto": ticketPhoto,
      "locationPhoto": locationPhoto,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return decoded;
    } else {
      final message = decoded['message'] ?? "Seyahat eklenemedi.";
      throw Exception(message);
    }
  }

  Future<List<dynamic>> getMyTravels() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/my"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final decoded = jsonDecode(response.body);
      final message = decoded['message'] ?? "Veriler alınamadı.";
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getFeedTravels() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Oturum bulunamadÄ±. LÃ¼tfen tekrar giriÅŸ yapÄ±n.");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/feed"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        "source": decoded["source"] ?? "global",
        "travels": decoded["travels"] ?? [],
      };
    }

    throw Exception(decoded["message"] ?? "Ana akis alinamadi.");
  }

  Future<List<dynamic>> searchTravels(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = "$baseUrl/search?q=$encodedQuery";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["travels"] ?? [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getUserApprovedTravels(String userId) async {
    try {
      final url = "$baseUrl/user/$userId";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["travels"] is List) {
          return data["travels"];
        }

        return [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getPendingTravelsForAdmin() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
    }

    final response = await http
        .get(
          Uri.parse("$baseUrl/admin/pending"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded["travels"] ?? [];
    }

    throw Exception(decoded["message"] ?? "Bekleyen seyahatler alınamadı.");
  }

  Future<Map<String, dynamic>> updateTravelVerificationStatus({
    required String travelId,
    required String verificationStatus,
  }) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
    }

    final response = await http
        .patch(
          Uri.parse("$baseUrl/admin/$travelId/status"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"verificationStatus": verificationStatus}),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return decoded;
    }

    throw Exception(decoded["message"] ?? "Seyahat durumu güncellenemedi.");
  }
}
