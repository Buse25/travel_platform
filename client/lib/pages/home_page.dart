import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/explore_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'public_profile_page.dart';
import 'travel_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> travels = [];
  List<dynamic> popularUsers = [];
  List<dynamic> newUsers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadExplore();
  }

  Future<void> loadExplore() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ExploreService.getExploreData();

    if (!mounted) return;

    setState(() {
      travels = result["travels"] ?? [];
      popularUsers = result["popularUsers"] ?? [];
      newUsers = result["newUsers"] ?? [];
      isLoading = false;
      if (result["success"] != true) {
        errorMessage = result["message"] ?? "Keşfet verileri alınamadı.";
      }
    });
  }

  String formatDate(dynamic value) {
    if (value == null) return "";
    final date = DateTime.tryParse(value.toString());
    if (date == null) return "";
    return "${date.day}.${date.month}.${date.year}";
  }

  ImageProvider? imageProvider(String image) {
    if (image.isEmpty) return null;
    return MemoryImage(base64Decode(image.split(",").last));
  }

  Widget buildAvatar(String profileImage, {double radius = 22}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepPurple,
      backgroundImage: imageProvider(profileImage),
      child: profileImage.isEmpty
          ? Icon(Icons.person, color: Colors.white, size: radius)
          : null,
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildTravelCard(Map<String, dynamic> travel) {
    final city = travel["city"] ?? "";
    final country = travel["country"] ?? "";
    final category = travel["category"] ?? "";
    final description = travel["description"] ?? "";
    final locationPhoto = travel["locationPhoto"] ?? "";
    final startDate = formatDate(travel["startDate"]);
    final endDate = formatDate(travel["endDate"]);
    final user = travel["user"] is Map<String, dynamic>
        ? Map<String, dynamic>.from(travel["user"])
        : <String, dynamic>{};
    final fullName = user["fullName"] ?? "";
    final username = user["username"] ?? "";
    final profileImage = user["profileImage"] ?? "";

    return Card(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TravelDetailPage(travel: travel)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  buildAvatar(profileImage),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (username.isNotEmpty)
                          Text(
                            "@$username",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            if (locationPhoto.isNotEmpty)
              Image.memory(
                base64Decode(locationPhoto.split(",").last),
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 190,
                color: Colors.deepPurple.shade50,
                child: const Icon(
                  Icons.travel_explore,
                  color: Colors.deepPurple,
                  size: 52,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$city, $country",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(category),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.deepPurple.shade50,
                        labelStyle: const TextStyle(color: Colors.deepPurple),
                      ),
                      if (startDate.isNotEmpty || endDate.isNotEmpty)
                        Chip(
                          label: Text("$startDate - $endDate"),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.grey.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserCard(
    Map<String, dynamic> user, {
    bool showFollowerCount = false,
  }) {
    final fullName = user["fullName"] ?? "";
    final username = user["username"] ?? "";
    final city = user["city"] ?? "";
    final profileImage = user["profileImage"] ?? "";
    final followerCount = user["followerCount"] ?? 0;

    return SizedBox(
      width: 164,
      child: Card(
        margin: const EdgeInsets.only(right: 10),
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PublicProfilePage(user: user)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildAvatar(profileImage, radius: 30),
                const SizedBox(height: 8),
                Text(
                  fullName.isNotEmpty ? fullName : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  username.isNotEmpty ? "@$username" : city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  showFollowerCount ? "$followerCount takipçi" : city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHorizontalUsers(
    List<dynamic> users, {
    required bool showFollowerCount,
    required String emptyText,
  }) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(emptyText, style: const TextStyle(color: Colors.black54)),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 14, right: 4),
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (context, index) {
          return buildUserCard(
            Map<String, dynamic>.from(users[index]),
            showFollowerCount: showFollowerCount,
          );
        },
      ),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: loadExplore,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar Dene"),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 760 ? 720.0 : double.infinity;

        return RefreshIndicator(
          onRefresh: loadExplore,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 18),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      buildSectionTitle("Son Seyahatler"),
                      if (travels.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text("Henüz gösterilecek seyahat yok."),
                        )
                      else
                        ...travels.map(
                          (travel) => buildTravelCard(
                            Map<String, dynamic>.from(travel),
                          ),
                        ),
                      buildSectionTitle("Popüler Gezginler"),
                      buildHorizontalUsers(
                        popularUsers,
                        showFollowerCount: true,
                        emptyText: "Henüz popüler gezgin yok.",
                      ),
                      buildSectionTitle("Yeni Katılanlar"),
                      buildHorizontalUsers(
                        newUsers,
                        showFollowerCount: false,
                        emptyText: "Henüz yeni kullanıcı yok.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keşfet")),
      body: buildContent(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}
