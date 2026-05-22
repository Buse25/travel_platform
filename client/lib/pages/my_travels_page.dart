import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import 'add_travel_page.dart';
import 'travel_detail_page.dart';

class MyTravelsPage extends StatefulWidget {
  const MyTravelsPage({super.key});

  @override
  State<MyTravelsPage> createState() => _MyTravelsPageState();
}

class _MyTravelsPageState extends State<MyTravelsPage> {
  List travels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);

    try {
      final data = await TravelService().getMyTravels();
      setState(() => travels = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }

    setState(() => isLoading = false);
  }

  void goToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTravelPage()),
    );

    if (result == true) fetch();
  }

  Widget travelCard(Map<String, dynamic> travel) {
    final city = travel["city"] ?? "";
    final country = travel["country"] ?? "";
    final status = travel["verificationStatus"] ?? "";
    final locationPhoto = travel["locationPhoto"] ?? "";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TravelDetailPage(travel: travel)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.deepPurple.shade50,
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (locationPhoto.isNotEmpty)
                Image.memory(
                  base64Decode(locationPhoto.split(",").last),
                  fit: BoxFit.cover,
                )
              else
                const Center(
                  child: Icon(
                    Icons.travel_explore,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$city, $country",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seyahatlerim")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : travels.isEmpty
          ? const Center(child: Text("Henüz seyahat eklenmemiş."))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: travels.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return travelCard(Map<String, dynamic>.from(travels[index]));
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
