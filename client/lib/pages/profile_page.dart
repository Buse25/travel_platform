import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/user_service.dart';
import '../services/travel_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'login_page.dart';
import 'profile_settings_page.dart';
import 'my_travels_page.dart';
import 'following_page.dart';
import 'add_travel_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;
  List<dynamic> myTravels = [];
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

    // Profil ve seyahat sayısını paralel çek
    final results = await Future.wait([
      UserService.getUserProfile(),
      TravelService().getMyTravels().catchError((_) => <dynamic>[]),
    ]);

    if (mounted) {
      setState(() {
        userProfile = results[0] as Map<String, dynamic>?;
        myTravels = results[1] as List<dynamic>;
        isLoading = false;

        if (userProfile == null) {
          errorMessage =
              "Profil bilgileri alınamadı.\nİnternet bağlantınızı veya oturumunuzu kontrol edin.";
        }
      });
    }
  }

  void handleLogout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  /// Instagram tarzı + butonu ile AddTravelPage'e git, dönünce yenile
  Future<void> _goToAddTravel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTravelPage()),
    );
    if (result == true) {
      loadAll(); // Yeni seyahat eklendiyse sayfayı yenile
    }
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
          // Instagram'daki + ikonuna benzer şekilde sağ üstte
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
        padding: const EdgeInsets.all(32.0),
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
    return RefreshIndicator(
      onRefresh: loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Profil Fotoğrafı ────────────────────────────────────
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                // Küçük + rozeti (isteğe bağlı, kaldırabilirsin)
                GestureDetector(
                  onTap: _goToAddTravel,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Ad Soyad & Kullanıcı Adı ────────────────────────────
            Text(
              userProfile!["fullName"] ?? "İsimsiz Kullanıcı",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "@${userProfile!["username"] ?? ""}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // ── İstatistik Satırı (Instagram tarzı) ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(myTravels.length.toString(), "Seyahat"),
                  _buildStatDivider(),
                  _buildStat(
                    userProfile!["followersCount"]?.toString() ?? "0",
                    "Takipçi",
                  ),
                  _buildStatDivider(),
                  _buildStat(
                    userProfile!["followingCount"]?.toString() ?? "0",
                    "Takip",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Seyahat Ekle Butonu (profil altında büyük) ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _goToAddTravel,
                  icon: const Icon(Icons.flight_takeoff, size: 18),
                  label: const Text("Yeni Seyahat Ekle"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Kişisel Bilgiler Kartı ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.email,
                        userProfile!["email"] ?? "Belirtilmemiş",
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.phone,
                        userProfile!["phone"] ?? "Belirtilmemiş",
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.location_city,
                        userProfile!["city"] ?? "Belirtilmemiş",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Menü Öğeleri ────────────────────────────────────────
            _buildMenuItem(Icons.settings, "Profil Ayarları", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
              );
            }),
            _buildMenuItem(Icons.card_travel, "Seyahatlerim", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyTravelsPage()),
              ).then((_) => loadAll()); // Geri dönünce sayacı güncelle
            }),
            _buildMenuItem(Icons.people, "Takip", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FollowingPage()),
              );
            }),
            _buildMenuItem(
              Icons.logout,
              "Çıkış Yap",
              () => handleLogout(context),
              isDestructive: true,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Yardımcı Widget'lar ─────────────────────────────────────────

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 32, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
