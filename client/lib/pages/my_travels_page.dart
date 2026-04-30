import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import 'add_travel_page.dart';

class MyTravelsPage extends StatefulWidget {
  const MyTravelsPage({super.key});

  @override
  State<MyTravelsPage> createState() => _MyTravelsPageState();
}

class _MyTravelsPageState extends State<MyTravelsPage> {
  List travels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);

    try {
      final data = await TravelService().getMyTravels();
      setState(() => travels = data);
    } catch (e) {
      print(e);
    }

    setState(() => isLoading = false);
  }

  void goToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTravelPage()),
    );

    if (result == true) fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seyahatlerim")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: travels.length,
              itemBuilder: (context, index) {
                final t = travels[index];

                return ListTile(
                  title: Text("${t['city']}, ${t['country']}"),
                  subtitle: Text(t['verificationStatus']),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}