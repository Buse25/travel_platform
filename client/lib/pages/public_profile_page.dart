import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/travel_service.dart';
import '../services/user_service.dart';
import 'chat_page.dart';
import 'travel_detail_page.dart';

class PublicProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const PublicProfilePage({super.key, required this.user});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  List<dynamic> travels = [];
  bool isLoading = true;
  bool isFollowLoading = false;
  bool isFollowing = false;
  bool isOwnProfile = false;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  String get profileUserId {
    return (widget.user["_id"] ?? widget.user["id"] ?? "").toString();
  }

  Future<void> loadProfileData() async {
    final userId = profileUserId;
    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final currentUserFuture = UserService.getUserProfile();
    final travelsFuture = TravelService().getUserApprovedTravels(userId);
    final statsFuture = FollowService.getFollowStats(userId);
    final followingFuture = FollowService.isFollowing(userId);

    final currentUser = await currentUserFuture;
    final loadedTravels = await travelsFuture;
    final stats = await statsFuture;
    final followed = await followingFuture;

    if (!mounted) return;

    final currentUserId = (currentUser?["_id"] ?? currentUser?["id"] ?? "")
        .toString();

    setState(() {
      travels = loadedTravels;
      followersCount = stats["followersCount"] ?? 0;
      followingCount = stats["followingCount"] ?? 0;
      isOwnProfile = currentUserId.isNotEmpty && currentUserId == userId;
      isFollowing = followed;
      isLoading = false;
    });
  }

  Future<void> toggleFollow() async {
    if (isFollowLoading || isOwnProfile) return;

    final userId = profileUserId;
    if (userId.isEmpty) return;

    setState(() {
      isFollowLoading = true;
    });

    final result = isFollowing
        ? await FollowService.unfollowUser(userId)
        : await FollowService.followUser(userId);

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        isFollowing = !isFollowing;
        followersCount += isFollowing ? 1 : -1;
        if (followersCount < 0) followersCount = 0;
      });
    }

    setState(() {
      isFollowLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "İşlem tamamlandı."),
        backgroundColor: result["success"] == true ? Colors.green : Colors.red,
      ),
    );
  }

  ImageProvider? imageProvider(String image) {
    if (image.isEmpty) return null;
    return MemoryImage(base64Decode(image.split(",").last));
  }

  Widget buildTravelBox(Map<String, dynamic> travel) {
    final city = travel["city"] ?? "";
    final country = travel["country"] ?? "";
    final locationPhoto = travel["locationPhoto"] ?? "";

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TravelDetailPage(travel: travel)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (locationPhoto.isNotEmpty)
              Image.memory(
                base64Decode(locationPhoto.split(",").last),
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.deepPurple.shade50,
                child: const Icon(
                  Icons.travel_explore,
                  color: Colors.deepPurple,
                  size: 42,
                ),
              ),
            Positioned(
              left: 7,
              right: 7,
              bottom: 7,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$city, $country",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.user["fullName"] ?? "";
    final username = widget.user["username"] ?? "";
    final city = widget.user["city"] ?? "";
    final profileImage = widget.user["profileImage"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("@$username"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatPage(user: widget.user)),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 720 ? 680.0 : double.infinity;
          final crossAxisCount = constraints.maxWidth > 620 ? 4 : 3;

          return SingleChildScrollView(
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
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.deepPurple,
                              backgroundImage: imageProvider(profileImage),
                              child: profileImage.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 46,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 10),
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatCard(
                                    travels.length.toString(),
                                    "Seyahat",
                                    Icons.travel_explore,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLoading && !isOwnProfile) ...[
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      isFollowLoading ? null : toggleFollow,
                                  icon: isFollowLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          isFollowing
                                              ? Icons.person_remove_alt_1
                                              : Icons.person_add_alt_1,
                                        ),
                                  label: Text(
                                    isFollowing ? "Takibi Bırak" : "Takip Et",
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing
                                        ? Colors.grey.shade200
                                        : Colors.deepPurple,
                                    foregroundColor: isFollowing
                                        ? Colors.black87
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Onaylanan Seyahatler (${travels.length})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      )
                    else if (travels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("Henüz onaylanan seyahati yok."),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: travels.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          return buildTravelBox(
                            Map<String, dynamic>.from(travels[index]),
                          );
                        },
                      ),
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
}
