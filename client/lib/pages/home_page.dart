import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSuggestedUsers();
  }

  Future<void> loadSuggestedUsers() async {
    setState(() {
      isLoading = true;
    });

    final result = await UserService.getSuggestedUsers();

    setState(() {
      users = result;
      isLoading = false;
    });
  }

  Future<void> handleSearch(String query) async {
    if (query.trim().isEmpty) {
      await loadSuggestedUsers();
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await UserService.searchUsers(query);

    setState(() {
      users = result;
      isLoading = false;
    });
  }

 
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ana Sayfa")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: handleSearch,
              decoration: InputDecoration(
                hintText: "Şehir, kullanıcı veya alan ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? const Center(child: Text("Sonuç bulunamadı."))
                : RefreshIndicator(
                    onRefresh: loadSuggestedUsers,
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        final username = user["username"] ?? "";
                        final fullName = user["fullName"] ?? "";
                        final city = user["city"] ?? "";
                        final interests = user["interests"] ?? [];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              fullName.isNotEmpty ? fullName : username,
                            ),
                            subtitle: Text(
                              "$username • $city"
                              "${interests.isNotEmpty ? " • ${interests.join(", ")}" : ""}",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}
