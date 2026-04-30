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
    final token = prefs.getString("jwt_token");
    print("[TravelService] Token: ${token != null ? 'VAR' : 'YOK'}");
    return token;
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

    print("[TravelService] createTravel URL: $baseUrl");
    print("[TravelService] createTravel body: $body");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("[TravelService] createTravel status: ${response.statusCode}");
    print("[TravelService] createTravel body: ${response.body}");

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

    print("[TravelService] getMyTravels URL: $baseUrl/my");

    final response = await http.get(
      Uri.parse("$baseUrl/my"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("[TravelService] getMyTravels status: ${response.statusCode}");
    print("[TravelService] getMyTravels body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final decoded = jsonDecode(response.body);
      final message = decoded['message'] ?? "Veriler alınamadı.";
      throw Exception(message);
    }
  }
}
