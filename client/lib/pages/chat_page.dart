import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: const Center(
        child: Text("Chat sayfası daha sonra geliştirilecek."),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
