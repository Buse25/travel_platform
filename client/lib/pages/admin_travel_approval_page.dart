import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import 'travel_detail_page.dart';

class AdminTravelApprovalPage extends StatefulWidget {
  const AdminTravelApprovalPage({super.key});

  @override
  State<AdminTravelApprovalPage> createState() =>
      _AdminTravelApprovalPageState();
}

class _AdminTravelApprovalPageState extends State<AdminTravelApprovalPage> {
  List<dynamic> travels = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTravels();
  }

  Future<void> loadTravels() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await TravelService().getPendingTravelsForAdmin();
      if (!mounted) return;
      setState(() {
        travels = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
        isLoading = false;
      });
    }
  }

  Future<void> updateStatus(String travelId, String status) async {
    try {
      await TravelService().updateTravelVerificationStatus(
        travelId: travelId,
        verificationStatus: status,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Seyahat $status olarak güncellendi.")),
      );
      await loadTravels();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildTravelCard(Map<String, dynamic> travel) {
    final id = travel["_id"]?.toString() ?? "";
    final city = travel["city"] ?? "";
    final country = travel["country"] ?? "";
    final category = travel["category"] ?? "";
    final description = travel["description"] ?? "";
    final locationPhoto = travel["locationPhoto"] ?? "";
    final user = travel["user"];
    final username = user is Map<String, dynamic> ? user["username"] ?? "" : "";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: locationPhoto.isNotEmpty
                      ? Image.memory(
                          base64Decode(locationPhoto.split(",").last),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          color: Colors.deepPurple.shade50,
                          child: const Icon(
                            Icons.travel_explore,
                            color: Colors.deepPurple,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$city, $country",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          category,
                          username.isNotEmpty ? "@$username" : "",
                        ].where((text) => text.isNotEmpty).join(" • "),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelDetailPage(travel: travel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text("Detay"),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: id.isEmpty
                      ? null
                      : () => updateStatus(id, "Reddedildi"),
                  icon: const Icon(Icons.close),
                  label: const Text("Reddet"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: id.isEmpty
                      ? null
                      : () => updateStatus(id, "Onaylandı"),
                  icon: const Icon(Icons.check),
                  label: const Text("Onayla"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seyahat Onayları")),
      body: RefreshIndicator(
        onRefresh: loadTravels,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              )
            : travels.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.task_alt, size: 48, color: Colors.green),
                  SizedBox(height: 16),
                  Text("Bekleyen seyahat yok.", textAlign: TextAlign.center),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: travels.length,
                itemBuilder: (context, index) {
                  return buildTravelCard(
                    Map<String, dynamic>.from(travels[index]),
                  );
                },
              ),
      ),
    );
  }
}
