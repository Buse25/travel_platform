import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../services/travel_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'add_travel_page.dart';
import 'admin_travel_approval_page.dart';
import 'following_page.dart';
import 'login_page.dart';
import 'my_travels_page.dart';
import 'profile_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;
  List<dynamic> myTravels = [];
  int followersCount = 0;
  int followingCount = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final profile = await UserService.getUserProfile();
    final travels = await TravelService().getMyTravels().catchError(
      (_) => <dynamic>[],
    );

    Map<String, int> stats = {
      "followersCount": 0,
      "followingCount": 0,
    };

    final userId = (profile?["_id"] ?? profile?["id"] ?? "").toString();
    if (userId.isNotEmpty) {
      stats = await FollowService.getFollowStats(userId);
    }

    if (!mounted) return;

    setState(() {
      userProfile = profile;
      myTravels = travels;
      followersCount = stats["followersCount"] ?? 0;
      followingCount = stats["followingCount"] ?? 0;
      isLoading = false;

      if (userProfile == null) {
        errorMessage =
            "Profil bilgileri alınamadı. İnternet bağlantınızı veya oturumunuzu kontrol edin.";
      }
    });
  }

  Future<void> handleLogout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _goToAddTravel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTravelPage()),
    );
    if (result == true) {
      loadAll();
    }
  }

  ImageProvider? _profileImageProvider(String image) {
    if (image.isEmpty) return null;
    return MemoryImage(base64Decode(image.split(",").last));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          userProfile != null
              ? "@${userProfile!["username"] ?? "Profil"}"
              : "Profil",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 28),
            tooltip: "Seyahat Ekle",
            onPressed: _goToAddTravel,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : _buildProfile(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar Dene"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final isAdmin = userProfile?["role"] == "admin";
    final fullName = userProfile!["fullName"] ?? "İsimsiz Kullanıcı";
    final username = userProfile!["username"] ?? "";
    final city = userProfile!["city"] ?? "Belirtilmemiş";
    final profileImage = userProfile!["profileImage"] ?? "";

    return RefreshIndicator(
      onRefresh: loadAll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 720 ? 680.0 : double.infinity;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Colors.deepPurple,
                                  backgroundImage:
                                      _profileImageProvider(profileImage),
                                  child: profileImage.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                GestureDetector(
                                  onTap: _goToAddTravel,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.deepPurple,
                                    ),
                                    padding: const EdgeInsets.all(7),
                                    child: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "@$username",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_city,
                                  size: 18,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(width: 6),
                                Text(city),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    myTravels.length.toString(),
                                    "Seyahat",
                                    Icons.flight_takeoff,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatCard(
                                    followersCount.toString(),
                                    "Takipçi",
                                    Icons.people_alt_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatCard(
                                    followingCount.toString(),
                                    "Takip",
                                    Icons.person_add_alt,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _goToAddTravel,
                                icon: const Icon(Icons.flight_takeoff),
                                label: const Text("Yeni Seyahat Ekle"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  side: const BorderSide(
                                    color: Colors.deepPurple,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildMenuCard(isAdmin),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.email, userProfile!["email"] ?? "Belirtilmemiş"),
            const Divider(),
            _buildInfoRow(Icons.phone, userProfile!["phone"] ?? "Belirtilmemiş"),
            const Divider(),
            _buildInfoRow(
              Icons.location_city,
              userProfile!["city"] ?? "Belirtilmemiş",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(bool isAdmin) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildMenuItem(Icons.settings, "Profil Ayarları", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ).then((_) => loadAll());
          }),
          _buildMenuItem(Icons.card_travel, "Seyahatlerim", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTravelsPage()),
            ).then((_) => loadAll());
          }),
          _buildMenuItem(Icons.people, "Takip", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FollowingPage()),
            ).then((_) => loadAll());
          }),
          if (isAdmin)
            _buildMenuItem(Icons.verified_user, "Seyahat Onayları", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminTravelApprovalPage(),
                ),
              );
            }),
          _buildMenuItem(
            Icons.logout,
            "Çıkış Yap",
            () => handleLogout(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.deepPurple,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
