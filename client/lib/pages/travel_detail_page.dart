import 'dart:convert';
import 'package:flutter/material.dart';

class TravelDetailPage extends StatelessWidget {
  final Map<String, dynamic> travel;

  const TravelDetailPage({super.key, required this.travel});

  String formatDate(dynamic value) {
    if (value == null) return "-";
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return "${date.day}.${date.month}.${date.year}";
  }

  Widget imageBox(String title, String image) {
    if (image.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            base64Decode(image.split(",").last),
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value.isEmpty ? "-" : value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final country = travel["country"] ?? "";
    final city = travel["city"] ?? "";
    final district = travel["district"] ?? "";
    final startDate = formatDate(travel["startDate"]);
    final endDate = formatDate(travel["endDate"]);
    final purpose = travel["purpose"] ?? "";
    final category = travel["category"] ?? "";
    final description = travel["description"] ?? "";
    final status = travel["verificationStatus"] ?? "";
    final ticketPhoto = travel["ticketPhoto"] ?? "";
    final locationPhoto = travel["locationPhoto"] ?? "";

    return Scaffold(
      appBar: AppBar(title: Text("$city, $country")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locationPhoto.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  base64Decode(locationPhoto.split(",").last),
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.travel_explore,
                  size: 70,
                  color: Colors.deepPurple,
                ),
              ),

            const SizedBox(height: 20),

            Text(
              "$city, $country",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Chip(
              label: Text(status),
              backgroundColor: status == "Onaylandı"
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
            ),

            const SizedBox(height: 20),

            infoRow(Icons.location_city, "İlçe", district),
            infoRow(Icons.date_range, "Başlangıç", startDate),
            infoRow(Icons.event_available, "Bitiş", endDate),
            infoRow(Icons.flag, "Amaç", purpose),
            infoRow(Icons.category, "Kategori", category),

            const Divider(height: 32),

            const Text(
              "Açıklama",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),

            const SizedBox(height: 24),

            imageBox("Bilet Fotoğrafı", ticketPhoto),
          ],
        ),
      ),
    );
  }
}
