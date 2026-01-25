import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        context
            .read<SubscriptionProvider>()
            .loadSubscription(profile['businessId']);
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

    final error = await context
        .read<AuthProvider>()
        .uploadProfileImage(bytes: bytes, fileName: name);

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
      builder: (_) => SubscriptionDialog(
        currentPlanId: currentPlan,
        businessId: businessId,
        onPlanSelected: (newPlan) {
          context
              .read<SubscriptionProvider>()
              .upgradePlan(businessId, newPlan);
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
                backgroundImage: photoURL.isNotEmpty
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
  Widget _businessCard(
      Map<String, dynamic> user,
      SubscriptionProvider sub,
      ) {
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

          _infoRow(Icons.business, "Company Code", businessId),

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

              if (user['role'] == 'admin' ||
                  user['role'] == 'super_admin')
                OutlinedButton(
                  onPressed: () => _showSubscriptionDialog(
                    context,
                    sub.currentSubscription['plan'],
                    businessId,
                  ),
                  child: Text(
                    "Upgrade",
                    style: GoogleFonts.roboto(),
                  ),
                ),
            ],
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
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey,
              ),
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}
