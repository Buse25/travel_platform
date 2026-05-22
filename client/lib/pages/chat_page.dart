import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? conversation;

  const ChatPage({super.key, this.user, this.conversation});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Map<String, dynamic>? conversation;
  Map<String, dynamic>? otherUser;
  List<dynamic> messages = [];
  String currentUserId = "";
  bool isLoading = true;
  bool isSending = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> initializeChat() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final profile = await UserService.getUserProfile();
      currentUserId = (profile?["_id"] ?? profile?["id"] ?? "").toString();

      if (widget.conversation != null) {
        conversation = widget.conversation;
        otherUser = widget.user;
      } else {
        final userId = (widget.user?["_id"] ?? widget.user?["id"] ?? "")
            .toString();
        if (userId.isEmpty) {
          throw Exception("Kullanici bilgisi bulunamadi.");
        }
        conversation = await ChatService.getOrCreateConversation(userId);
        otherUser = widget.user;
      }

      final conversationId = (conversation?["_id"] ?? "").toString();
      if (conversationId.isEmpty) {
        throw Exception("Konusma bilgisi bulunamadi.");
      }

      final loadedMessages = await ChatService.getMessages(conversationId);
      await ChatService.markConversationAsRead(conversationId);

      if (!mounted) return;

      setState(() {
        messages = loadedMessages.map((message) {
          if (message is Map<String, dynamic> && !isMine(message)) {
            return {
              ...message,
              "read": true,
            };
          }
          return message;
        }).toList();
        isLoading = false;
      });

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Konuşma yüklenemedi.";
      });
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending) return;

    final conversationId = (conversation?["_id"] ?? "").toString();
    if (conversationId.isEmpty) return;

    setState(() {
      isSending = true;
    });

    try {
      final message = await ChatService.sendMessage(
        conversationId: conversationId,
        text: text,
      );

      if (!mounted) return;

      if (message != null) {
        setState(() {
          messages.add(message);
          messageController.clear();
        });
        scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mesaj gönderilemedi."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  ImageProvider? imageProvider(String image) {
    if (image.isEmpty) return null;
    return MemoryImage(base64Decode(image.split(",").last));
  }

  bool isMine(Map<String, dynamic> message) {
    final sender = message["sender"];
    if (sender is Map<String, dynamic>) {
      final senderId = (sender["_id"] ?? sender["id"] ?? "").toString();
      return senderId == currentUserId;
    }
    return sender.toString() == currentUserId;
  }

  String formatTime(dynamic value) {
    if (value == null) return "";
    final date = DateTime.tryParse(value.toString());
    if (date == null) return "";
    final hour = date.toLocal().hour.toString().padLeft(2, "0");
    final minute = date.toLocal().minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }

  Widget buildMessageBubble(Map<String, dynamic> message) {
    final mine = isMine(message);
    final text = message["text"] ?? "";
    final time = formatTime(message["createdAt"]);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: EdgeInsets.only(
          left: mine ? 56 : 12,
          right: mine ? 12 : 56,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: mine ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
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
                onPressed: initializeChat,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar Dene"),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text("Henüz mesaj yok."))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 760
                        ? 720.0
                        : double.infinity;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return buildMessageBubble(
                              Map<String, dynamic>.from(messages[index]),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        buildComposer(),
      ],
    );
  }

  Widget buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Mesaj yaz...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: isSending ? null : sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayUser = otherUser ?? widget.user ?? {};
    final fullName = displayUser["fullName"] ?? "";
    final username = displayUser["username"] ?? "";
    final profileImage = displayUser["profileImage"] ?? "";

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurple,
              backgroundImage: imageProvider(profileImage),
              child: profileImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (username.isNotEmpty)
                    Text(
                      "@$username",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: buildBody(),
    );
  }
}
