
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/client_provider.dart';
import '../../../utils/my_colors.dart';
import 'create_client_screen.dart';
import 'edit_client_screen.dart';

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({super.key});

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> filteredClients = [];
  int hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<ClientProvider>();
      await provider.fetchClients();

      filteredClients = provider.clients;
      setState(() {});
    });

    searchController.addListener(_applySearch);
  }

  void _applySearch() {
    final provider = context.read<ClientProvider>();
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredClients = provider.clients.where((c) {
        final name = (c["name"] ?? "").toString().toLowerCase();
        final email = (c["email"] ?? "").toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();

    return Scaffold(
      backgroundColor: MyColors.softWhite,

      appBar: AppBar(
        backgroundColor: MyColors.darkShade,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          "Manage Clients",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.accent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClientScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: provider.isLoading || provider.clients.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Container(
              width: MediaQuery.of(context).size.width * (kIsWeb ? 0.60 : 0.90),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                Border.all(color: MyColors.darkShade, width: 1.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: MyColors.darkShade),
                  hintText: "Search clients by name or email...",
                  hintStyle: GoogleFonts.roboto(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CLIENT LIST
            Expanded(
              child: filteredClients.isEmpty
                  ? Center(
                child: Text(
                  "No clients found",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: MyColors.darkShade,
                  ),
                ),
              )
                  : _buildClientList(provider),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // CLIENT LIST UI (matches ManageUsersScreen exactly)
  // -----------------------------------------------------------
  Widget _buildClientList(ClientProvider provider) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * (kIsWeb ? 0.50 : 0.90),
        child: ListView.builder(
          itemCount: filteredClients.length,
          itemBuilder: (_, i) {
            final client = filteredClients[i];
            final isHovered = hoveredIndex == i;

            return MouseRegion(
              onEnter: (_) => setState(() => hoveredIndex = i),
              onExit: (_) => setState(() => hoveredIndex = -1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isHovered ? MyColors.darkShade : Colors.grey.shade300,
                    width: isHovered ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (isHovered)
                      BoxShadow(
                        color: MyColors.darkShade.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),

                // 👉 Entire tile clickable to edit client
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditClientScreen(client: client),
                      ),
                    );
                  },

                  title: Text(
                    client["name"] ?? "Unknown Client",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: MyColors.darkShade,
                    ),
                  ),

                  subtitle: Text(
                    "${client["email"] ?? "No email"} • ${client["contact"] ?? "No contact"}",
                    style: GoogleFonts.roboto(color: Colors.black87),
                  ),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await _confirmDelete(context);
                      if (confirm == true) {
                        await provider.deleteClient(client["id"]);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  // -----------------------------------------------------------
  // CONFIRM DELETE POPUP
  // -----------------------------------------------------------
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
