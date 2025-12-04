import 'package:flutter/material.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Reports")),
      body: const Center(
        child: Text(
          "Reports Dashboard",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
