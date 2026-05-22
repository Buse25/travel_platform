import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/travel_service.dart';
import 'travel_detail_page.dart';
import 'chat_page.dart';
import 'public_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> travels = [];

  bool isLoading = false;
  String query = "";

  Future<void> search(String value) async {
    query = value.trim();

    if (query.isEmpty) {
      setState(() {
        users = [];
        travels = [];
      });
      return;
    }

    setState(() => isLoading = true);

    final userResults = await UserService.searchUsers(query);
    final travelResults = await TravelService().searchTravels(query);

    if (!mounted) return;

    setState(() {
      users = userResults;
      travels = travelResults;
      isLoading = false;
    });
  }

  Widget buildUserCard(Map<String, dynamic> user) {
    final fullName = user["fullName"] ?? "";
    final username = user["username"] ?? "";
    final city = user["city"] ?? "";
    final profileImage = user["profileImage"] ?? "";

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple,
        backgroundImage: profileImage.isNotEmpty
            ? MemoryImage(base64Decode(profileImage.split(",").last))
            : null,
        child: profileImage.isEmpty
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("@$username • $city"),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage(user: user)),
          );
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PublicProfilePage(user: user)),
        );
      },
    );
  }

  Widget buildTravelCard(Map<String, dynamic> travel) {
    final city = travel["city"] ?? "";
    final country = travel["country"] ?? "";
    final category = travel["category"] ?? "";
    final description = travel["description"] ?? "";
    final locationPhoto = travel["locationPhoto"] ?? "";
    final user = travel["user"];

    String ownerText = "";
    if (user is Map<String, dynamic>) {
      ownerText = user["username"] != null ? "@${user["username"]}" : "";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TravelDetailPage(travel: travel)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: locationPhoto.isNotEmpty
                    ? Image.memory(
                        base64Decode(locationPhoto.split(",").last),
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 86,
                        height: 86,
                        color: Colors.deepPurple.shade50,
                        child: const Icon(
                          Icons.travel_explore,
                          color: Colors.deepPurple,
                          size: 36,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$category $ownerText",
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = users.isNotEmpty || travels.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Arama")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: search,
              decoration: InputDecoration(
                hintText: "İsim, kullanıcı adı, şehir, kategori ara...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          search("");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (query.isEmpty)
              const Expanded(
                child: Center(
                  child: Text("Kullanıcı, şehir veya seyahat arayabilirsin."),
                ),
              )
            else if (!hasResult)
              const Expanded(child: Center(child: Text("Sonuç bulunamadı.")))
            else
              Expanded(
                child: ListView(
                  children: [
                    if (users.isNotEmpty) ...[
                      const Text(
                        "Kullanıcılar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...users.map(
                        (user) =>
                            buildUserCard(Map<String, dynamic>.from(user)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (travels.isNotEmpty) ...[
                      const Text(
                        "Seyahatler",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...travels.map(
                        (travel) =>
                            buildTravelCard(Map<String, dynamic>.from(travel)),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
