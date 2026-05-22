import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<dynamic> conversations = [];
  String currentUserId = "";
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final profile = await UserService.getUserProfile();
      final result = await ChatService.getConversations();

      if (!mounted) return;

      setState(() {
        currentUserId = (profile?["_id"] ?? profile?["id"] ?? "").toString();
        conversations = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Konuşmalar yüklenemedi.";
      });
    }
  }

  Map<String, dynamic> otherParticipant(Map<String, dynamic> conversation) {
    final participants = conversation["participants"];
    if (participants is! List) return {};

    for (final participant in participants) {
      if (participant is Map<String, dynamic>) {
        final id = (participant["_id"] ?? participant["id"] ?? "").toString();
        if (id != currentUserId) return participant;
      }
    }

    if (participants.isNotEmpty && participants.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(participants.first);
    }

    return {};
  }

  ImageProvider? imageProvider(String image) {
    if (image.isEmpty) return null;
    return MemoryImage(base64Decode(image.split(",").last));
  }

  String formatDate(dynamic value) {
    if (value == null) return "";
    final date = DateTime.tryParse(value.toString());
    if (date == null) return "";
    return "${date.day}.${date.month}.${date.year}";
  }

  Widget buildConversationTile(Map<String, dynamic> conversation) {
    final user = otherParticipant(conversation);
    final fullName = user["fullName"] ?? "";
    final username = user["username"] ?? "";
    final profileImage = user["profileImage"] ?? "";
    final lastMessage = conversation["lastMessage"];
    final lastText = lastMessage is Map<String, dynamic>
        ? (lastMessage["text"] ?? "")
        : "Henüz mesaj yok.";
    final dateText = formatDate(conversation["updatedAt"]);
    final unreadCount = conversation["unreadCount"] ?? 0;
    final hasUnread = unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.deepPurple,
          backgroundImage: imageProvider(profileImage),
          child: profileImage.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName.isNotEmpty ? fullName : username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            if (hasUnread)
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Text(
          lastText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateText,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 5),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unreadCount > 99 ? "99+" : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                user: user,
                conversation: conversation,
              ),
            ),
          ).then((_) => loadConversations());
        },
      ),
    );
  }

  Widget buildBody() {
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
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: loadConversations,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar Dene"),
              ),
            ],
          ),
        ),
      );
    }

    if (conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadConversations,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(Icons.chat_bubble_outline, size: 58, color: Colors.grey),
            SizedBox(height: 14),
            Center(child: Text("Henüz konuşma yok.")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadConversations,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 720 ? 680.0 : double.infinity;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: conversations
                        .map(
                          (conversation) => buildConversationTile(
                            Map<String, dynamic>.from(conversation),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mesajlar")),
      body: buildBody(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
