import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget adminButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Welcome, Administrator!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔵 Manage Businesses
                  adminButton(
                    label: "Manage Businesses",
                    color: Colors.blue,
                    onTap: () {
                      context.push("/admin/businesses");
                    },
                  ),

                  const SizedBox(height: 12),

                  // 🟢 Manage Users
                  adminButton(
                    label: "Manage Users",
                    color: Colors.green,
                    onTap: () {
                      context.push("/admin/users");
                    },
                  ),

                  const SizedBox(height: 12),

                  // 🟣 Manage Clients
                  adminButton(
                    label: "Manage Clients",
                    color: Colors.indigo,
                    onTap: () {
                      context.push("/admin/clients");
                    },
                  ),

                  const SizedBox(height: 12),

                  // 🟠 View Reports
                  adminButton(
                    label: "View Reports",
                    color: Colors.orange,
                    onTap: () {
                      context.push("/admin/reports");
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 30),

                  // 🔴 Logout
                  GestureDetector(
                    onTap: () async {
                      await auth.logout();
                      if (!context.mounted) return;
                      context.go("/login");
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
