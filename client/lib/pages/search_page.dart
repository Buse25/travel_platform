import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arama")),
      body: const Center(
        child: Text("Arama sayfası daha sonra geliştirilecek."),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}
