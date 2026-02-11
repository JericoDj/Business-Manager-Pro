import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/manage_user_provider.dart';
import '../../../utils/my_colors.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> filteredUsers = [];

  int hoveredIndex = -1;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider = Provider.of<ManageUserProvider>(context, listen: false);

      // 🔥 Load users first
      await provider.fetchUsers();

      // 🔥 After loading, apply the full list
      filteredUsers = provider.users;
      setState(() {});
    });

    searchController.addListener(_applySearch);
  }

  void _applySearch() {
    final provider = Provider.of<ManageUserProvider>(context, listen: false);
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredUsers =
          provider.users.where((u) {
            final name = (u["name"] ?? "").toString().toLowerCase();
            final email = (u["email"] ?? "").toString().toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ManageUserProvider>(context);

    return Scaffold(
      backgroundColor: MyColors.softWhite,

      appBar: AppBar(
        backgroundColor: MyColors.darkShade,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          "Manage Users",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.accent,
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body:
          provider.isLoading || provider.users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // SEARCH BAR
                    Container(
                      width:
                          MediaQuery.of(context).size.width *
                          (kIsWeb ? 0.60 : 0.90),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: MyColors.darkShade,
                          width: 1.4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: MyColors.darkShade,
                          ),
                          hintText: "Search users by name or email...",
                          hintStyle: GoogleFonts.roboto(),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child:
                          filteredUsers.isEmpty
                              ? Center(
                                child: Text(
                                  "No users found",
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color: MyColors.darkShade,
                                  ),
                                ),
                              )
                              : _buildUserList(provider),
                    ),
                  ],
                ),
              ),
    );
  }

  // -------------------------------------------------------------
  // ADD USER POPUP DIALOG (STYLED)
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
      builder:
          (_) => AlertDialog(
            backgroundColor: MyColors.lightShade,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            title: Text(
              "Add User",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: MyColors.darkShade,
              ),
            ),

            content: SingleChildScrollView(
              child: Column(
                children: [
                  _dialogField("Full Name", name),
                  _dialogField("Phone Number", phone),
                  _dialogField("Email", email),
                  _dialogField("Home Address", address),

                  // TextField(
                  //   controller: birth,
                  //   readOnly: true,
                  //   decoration: const InputDecoration(
                  //     labelText: "Birth Date",
                  //     border: OutlineInputBorder(),
                  //   ),
                  //   onTap: () async {
                  //     final date = await showDatePicker(
                  //       context: context,
                  //       firstDate: DateTime(1950),
                  //       lastDate: DateTime.now(),
                  //       initialDate: DateTime(2000),
                  //     );
                  //     if (date != null) {
                  //       birth.text = "${date.month}/${date.day}/${date.year}";
                  //     }
                  //   },
                  // ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: GoogleFonts.roboto()),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.darkShade,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                child: Text(
                  "Save",
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // ------------------ Reusable dialog field ------------------
  Widget _dialogField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildUserList(ManageUserProvider provider) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * (kIsWeb ? 0.50 : 0.90),
        child: ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (_, i) {
            final user = filteredUsers[i];
            final isHovered = hoveredIndex == i;
            final role = (user["role"] ?? "User").toString();
            // Capitalize first letter
            final displayRole =
                role.isNotEmpty
                    ? role[0].toUpperCase() + role.substring(1)
                    : "User";

            final docCount = user["documentCount"] ?? 0;

            return MouseRegion(
              onEnter: (_) => setState(() => hoveredIndex = i),
              onExit: (_) => setState(() => hoveredIndex = -1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color:
                        isHovered ? MyColors.darkShade : Colors.grey.shade300,
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
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    user["name"] ?? "Unknown",
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: MyColors.darkShade,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user["email"] ?? "No email",
                        style: GoogleFonts.roboto(color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MyColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayRole,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: MyColors.darkShade,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Documents: $docCount / 11",
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  docCount == 11 ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    final isAdmin = role == 'admin' || role == 'super_admin';

                    if (isAdmin) {
                      _showUserDetailsDialog(context, user);
                    } else {
                      final name = user["name"] ?? "";
                      final email = user["email"] ?? "";
                      context.push("/admin/user-docs?name=$name&email=$email");
                    }
                  },
                  trailing: GestureDetector(
                    onTap: () => provider.deleteUser(user["docId"]),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "User Details",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: MyColors.darkShade,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Name", user["name"]),
                _detailRow("Email", user["email"]),
                _detailRow("Role", user["role"] ?? "N/A"),
                _detailRow("Phone", user["phone"] ?? "N/A"),
                _detailRow("Address", user["homeAddress"] ?? "N/A"),
                const SizedBox(height: 10),
                // We could add an "Edit" button logic here later if needed
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.roboto(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value ?? "N/A"),
          ],
        ),
      ),
    );
  }
}
