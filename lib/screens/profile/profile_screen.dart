import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/subscription_dialog.dart';
import '../../utils/my_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final profile = auth.currentUserProfile;
      if (profile != null && profile['businessId'] != null) {
        context.read<SubscriptionProvider>().loadSubscription(
          profile['businessId'],
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || !mounted) return;

    final bytes = result.files.first.bytes;
    final name = result.files.first.name;

    if (bytes == null) return;

    final error = await context.read<AuthProvider>().uploadProfileImage(
      bytes: bytes,
      fileName: name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? "Profile image updated" : "Upload failed: $error",
        ),
      ),
    );
  }

  void _showSubscriptionDialog(
    BuildContext context,
    String currentPlan,
    String businessId,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => SubscriptionDialog(
            currentPlanId: currentPlan,
            businessId: businessId,
            onPlanSelected: (newPlan) {
              context.read<SubscriptionProvider>().upgradePlan(
                businessId,
                newPlan,
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();

    final user = auth.currentUserProfile;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final contentWidth = width * (kIsWeb ? 0.45 : 0.90);

    return Scaffold(
      backgroundColor: MyColors.softWhite,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: MyColors.darkShade,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
      ),

      // ---------------- BODY ----------------
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: contentWidth,
            child: Column(
              children: [
                _profileHeader(user),
                const SizedBox(height: 24),
                _businessCard(user, sub),
                const SizedBox(height: 24),
                _logoutButton(auth),
                const SizedBox(height: 12),
                _deleteAccountButton(auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE HEADER
  // ------------------------------------------------------------
  Widget _profileHeader(Map<String, dynamic> user) {
    final photoURL = user['photoURL'] ?? "";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : const AssetImage("assets/default_avatar.png")
                            as ImageProvider,
              ),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MyColors.darkShade,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            user['name'] ?? "User",
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MyColors.darkShade,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            user['email'] ?? "",
            style: GoogleFonts.roboto(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          Chip(
            label: Text(
              (user['role'] ?? "employee").toUpperCase(),
              style: GoogleFonts.roboto(
                color: MyColors.darkShade,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: MyColors.accent.withOpacity(0.15),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUSINESS + SUBSCRIPTION CARD
  // ------------------------------------------------------------
  Widget _businessCard(Map<String, dynamic> user, SubscriptionProvider sub) {
    final businessId = user['businessId'] ?? "—";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Business & Subscription",
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyColors.darkShade,
            ),
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.business,
            "Company",
            user['companyName'] ?? user['businessId'] ?? "—",
          ),

          // Show company code with copy button only for admin/super_admin
          if (user['role'] == 'admin' || user['role'] == 'super_admin') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.vpn_key, color: MyColors.darkShade),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Company Code",
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        user['businessId'] ?? "—",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MyColors.darkShade,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: "Copy Company Code",
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: user['businessId'] ?? ""),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Company code copied!")),
                    );
                  },
                ),
              ],
            ),
          ],

          const Divider(height: 32),

          Row(
            children: [
              const Icon(Icons.card_membership, color: Colors.orange),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Plan",
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    sub.isLoading
                        ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          sub.currentPlanDetails['name'] ?? "Free",
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                  ],
                ),
              ),

              if (user['role'] == 'admin' || user['role'] == 'super_admin')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed:
                          () => _showSubscriptionDialog(
                            context,
                            sub.currentSubscription['plan'],
                            businessId,
                          ),
                      child: Text("Upgrade", style: GoogleFonts.roboto()),
                    ),
                    if ((sub.currentPlanDetails['price'] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: InkWell(
                          onTap:
                              () => _confirmCancellation(
                                context,
                                sub,
                                businessId,
                              ),
                          child: Text(
                            "Cancel Subscription",
                            style: GoogleFonts.roboto(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancellation(
    BuildContext context,
    SubscriptionProvider sub,
    String businessId,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Cancel Subscription?"),
            content: const Text(
              "Are you sure you want to cancel? You will lose access to premium features at the end of your billing period.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Keep Subscription"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  try {
                    // businessId is passed from _businessCard -> _confirmCancellation
                    await sub.cancelSubscription(businessId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Subscription cancellation requested."),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to cancel: $e")),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Cancel Now"),
              ),
            ],
          ),
    );
  }

  // ------------------------------------------------------------
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: MyColors.darkShade),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MyColors.darkShade,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  Widget _logoutButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: auth.logout,
        icon: const Icon(Icons.logout),
        label: Text(
          "Log Out",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DELETE ACCOUNT BUTTON
  // ------------------------------------------------------------
  Widget _deleteAccountButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _confirmDeleteAccount(auth),
        icon: const Icon(Icons.delete_forever, size: 20),
        label: Text("Delete Account", style: GoogleFonts.roboto(fontSize: 14)),
      ),
    );
  }

  void _confirmDeleteAccount(AuthProvider auth) {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Delete Account"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This action is permanent and cannot be undone. "
                    "All your data will be deleted.",
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text("Enter your password to confirm:"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed:
                      isDeleting
                          ? null
                          : () async {
                            if (passwordController.text.trim().isEmpty) return;

                            setDialogState(() => isDeleting = true);

                            final error = await auth.deleteAccount(
                              passwordController.text.trim(),
                            );

                            if (!context.mounted) return;

                            if (error != null) {
                              setDialogState(() => isDeleting = false);
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                            } else {
                              Navigator.pop(ctx);
                              context.go("/login");
                            }
                          },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child:
                      isDeleting
                          ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text("Delete Permanently"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
