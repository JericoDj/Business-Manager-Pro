import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_business_manager/utils/my_colors.dart';
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MyColors.darkShade, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final box = GetStorage();
    final profile = box.read("profile");
    final companyName =
        profile != null
            ? (profile["companyName"] ?? profile["businessId"] ?? "My Business")
            : "My Business";
    final photoURL = profile != null ? profile["photoURL"] : null;

    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MyColors.darkShade, width: 1.4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------ HERO LOGO ------------------
                Hero(
                  tag: "app_logo",
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.20,
                    child: Image.asset(
                      "assets/icons/app_logo_nobackground.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ------------------ PROFILE IMAGE ------------------
                GestureDetector(
                  onTap: () => context.push("/profile"),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        photoURL != null && photoURL.isNotEmpty
                            ? NetworkImage(photoURL)
                            : const AssetImage("assets/default_avatar.png")
                                as ImageProvider,
                  ),
                ),

                const SizedBox(height: 10),

                // ------------------ APP NAME ------------------
                Text(
                  companyName,
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                Text(
                  "My Business Manager",
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                // ------------------ TAGLINE ------------------
                Text(
                  "Smart Tools for Modern Businesses",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: MyColors.darkShade.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  "Admin Dashboard",
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MyColors.darkShade,
                  ),
                ),

                const SizedBox(height: 25),

                // 🟢 Manage Users
                adminButton(
                  label: "Manage Users",
                  color: MyColors.darkShade,
                  onTap: () => context.push("/admin/users"),
                ),

                const SizedBox(height: 12),

                // 🟣 Manage Clients
                adminButton(
                  label: "Manage Clients",
                  color: MyColors.accent,
                  onTap: () => context.push("/admin/clients"),
                ),

                const SizedBox(height: 12),

                // 🔵 Manage Company Documents
                adminButton(
                  label: "Company Documents",
                  color: Colors.blue, // Using a distinct color
                  onTap: () => context.push("/admin/company-documents"),
                ),

                const SizedBox(height: 12),

                // (Optional future section)
                // adminButton(
                //   label: "My Notes",
                //   color: Colors.orange,
                //   onTap: () => context.push("/admin/notes"),
                // ),
                const SizedBox(height: 25),
                const Divider(),

                // ------------------ LOGOUT BUTTON ------------------
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
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade700, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Logout",
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
