import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ExploreService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api/explore";
    }
    return "http://10.0.2.2:5000/api/explore";
  }

  static Future<Map<String, dynamic>> getExploreData() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "travels": data["travels"] ?? [],
          "popularUsers": data["popularUsers"] ?? [],
          "newUsers": data["newUsers"] ?? [],
        };
      }

      return {
        "success": false,
        "message": "Kesfet verileri alinamadi.",
        "travels": [],
        "popularUsers": [],
        "newUsers": [],
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Sunucu baglanti hatasi.",
        "travels": [],
        "popularUsers": [],
        "newUsers": [],
      };
    }
  }
}
