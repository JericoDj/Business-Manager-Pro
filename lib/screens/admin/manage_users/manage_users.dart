import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/manage_user_provider.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ManageUserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        automaticallyImplyLeading: true,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.add),
      ),

      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: provider.users.length,
        itemBuilder: (_, i) {
          final user = provider.users[i];

          return ListTile(
            title: Text(user["name"] ?? "Unnamed User"),
            subtitle: Text(user["email"] ?? "No email"),

              onTap: () {
                final name = user["name"] ?? "";
                final email = user["email"] ?? "";

                context.push("/admin/user-docs?name=$name&email=$email");
              },

            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                final docId = user["docId"];
                provider.deleteUser(docId);
              },
            ),
          );

        },
      ),
    );
  }

  // -------------------------------------------------------------
  // ADD USER POPUP DIALOG
  // -------------------------------------------------------------
  void _showAddUserDialog(BuildContext context) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();
    final birth = TextEditingController();

    final provider = Provider.of<ManageUserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add User"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone Number")),
              TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: address, decoration: const InputDecoration(labelText: "Home Address")),

              TextField(
                controller: birth,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Birth Date"),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );

                  if (date != null) {
                    birth.text = "${date.month}/${date.day}/${date.year}";
                  }
                },
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              final error = await provider.addUser(
                name: name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim(),
                homeAddress: address.text.trim(),
                birthDate: birth.text.trim(),
              );

              if (context.mounted) Navigator.pop(context);

              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
