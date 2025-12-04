import 'package:flutter/material.dart';

class ManageBusinessesScreen extends StatelessWidget {
  const ManageBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Businesses")),
      body: const Center(
        child: Text(
          "Business Management Screen",
          style: TextStyle(fontSize: 20),
        ),

      ),
    );
  }
}
