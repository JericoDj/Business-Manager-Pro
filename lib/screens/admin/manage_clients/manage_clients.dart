import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/client_provider.dart';
import 'create_client_screen.dart';
import 'edit_client_screen.dart';

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({super.key});

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().fetchClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Clients")),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClientScreen()),
          );
        },
      ),

      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.clients.isEmpty
          ? const Center(child: Text("No clients found"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.clients.length,
        itemBuilder: (_, i) {
          final client = provider.clients[i];

          final email = client["email"] ?? "No email";
          final contact = client["contact"] ?? "No contact";

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                client["name"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text("$email • $contact"),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditClientScreen(client: client),
                        ),
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await _confirmDelete(context);
                      if (confirm == true) {
                        await provider.deleteClient(client["id"]);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Client"),
        content: const Text("Are you sure you want to delete this client?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
