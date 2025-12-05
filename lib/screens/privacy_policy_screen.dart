import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_business_manager/utils/my_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.softWhite,
      appBar: AppBar(
        backgroundColor: MyColors.darkShade,
        foregroundColor: Colors.white,
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.notoSerifJp(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20,),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width *
                    (MediaQuery.of(context).size.width > 600 ? 0.65 : 0.90),
        
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header("Privacy Policy"),
                          const SizedBox(height: 10),
                          _text(
                            "Your privacy is important to us. This Privacy Policy explains "
                                "how My Business Manager collects, uses, and protects your data "
                                "while using the app.",
                          ),
        
                          const SizedBox(height: 20),
                          _header("Information We Collect"),
                          _bullet("Personal details such as name, email, and contact information."),
                          _bullet("Employee documents and uploaded files."),
                          _bullet("Business-related data for management and verification."),
                          _bullet("App usage analytics to improve performance."),
        
                          const SizedBox(height: 20),
                          _header("How We Use Your Information"),
                          _bullet("To manage employee and client records."),
                          _bullet("To store and track important documents."),
                          _bullet("To send notifications about expiring requirements."),
                          _bullet("To improve app functionality and user experience."),
        
                          const SizedBox(height: 20),
                          _header("Data Protection"),
                          _text(
                            "All data is securely stored in cloud infrastructure. "
                                "We do not sell or share your information with third parties.",
                          ),
        
                          const SizedBox(height: 20),
                          _header("Your Rights"),
                          _bullet("Request access to your stored information."),
                          _bullet("Request correction or deletion of your data."),
                          _bullet("Withdraw consent for data processing."),
        
                          const SizedBox(height: 20),
                          _header("Contact Us"),
                          _text(
                            "If you have questions about this Privacy Policy, "
                                "please contact our support team.",
                          ),
        
                          const SizedBox(height: 30),
                          Center(
                            child: Text(
                              "Last Updated: January 2025",
                              style: GoogleFonts.notoSerifJp(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          SizedBox(height: 20,),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSerifJp(
        fontSize: 20,
        color: MyColors.darkShade,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _text(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSerifJp(
        fontSize: 15,
        height: 1.5,
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSerifJp(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
