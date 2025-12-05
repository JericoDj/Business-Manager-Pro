
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/document_provider.dart';
import '../../../utils/my_colors.dart';

class AdminUserDocumentDashboardScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const AdminUserDocumentDashboardScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<AdminUserDocumentDashboardScreen> createState() =>
      _AdminUserDocumentDashboardScreenState();
}

class _AdminUserDocumentDashboardScreenState
    extends State<AdminUserDocumentDashboardScreen> {
  final documents = const [
    "Resume",
    "License ID",
    "CPR Certification",
    "Driver’s License",
    "Physical",
    "TB Test Result",
    "Background Check",
    "Hepatitis B Vaccination",
    "Social Security Card",
    "High School Diploma / GED",
    "COVID Vaccine",
  ];

  // For Web hover effect
  int hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadDocs());
  }

  Future<void> loadDocs() async {
    await context.read<DocumentProvider>().adminLoadUserDocuments(
      fullName: widget.fullName,
      email: widget.email,
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      backgroundColor: MyColors.softWhite,
      appBar: AppBar(
        backgroundColor: MyColors.darkShade,
        foregroundColor: Colors.white,
        title: Text(
          "Documents: ${widget.fullName}",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: Container(
          width: kIsWeb ? 700 : double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fullName,
                style: GoogleFonts.roboto(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: MyColors.darkShade,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Required Documents",
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MyColors.darkShade,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, i) {
                    final title = documents[i];
                    final status =
                    docProvider.getStatusForDoc(title).toLowerCase();

                    return _documentCard(i, title, status);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // DOCUMENT TILE (CARD STYLE)
  // -----------------------------
  Widget _documentCard(int index, String title, String status) {
    Color statusColor = Colors.grey;

    switch (status) {
      case "approved":
        statusColor = Colors.green;
        break;
      case "processing":
        statusColor = Colors.orange;
        break;
      case "rejected":
        statusColor = Colors.red;
        break;
      case "expired":
        statusColor = Colors.red.shade800;
        break;
      case "near expiry":
        statusColor = Colors.orange.shade700;
        break;
    }

    final isHovered = hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _openDocumentDetails(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Icon(Icons.folder_copy, color: MyColors.darkShade),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: MyColors.darkShade,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Status: $status",
                      style: GoogleFonts.roboto(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // EDIT BUTTON (visible on hover for web, always visible on mobile)
              if (kIsWeb ? isHovered : true)
                GestureDetector(
                  onTap: () => _openDocumentDetails(title),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MyColors.lightShade,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MyColors.darkShade),
                    ),
                    child: Text(
                      "Edit",
                      style: GoogleFonts.roboto(
                        color: MyColors.darkShade,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // OPEN DOCUMENT DETAIL PAGE
  // -----------------------------
  Future<void> _openDocumentDetails(String docType) async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: widget.fullName)
        .where("email", isEqualTo: widget.email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User record not found")),
      );
      return;
    }

    final userId = snap.docs.first.id;

    context.push(
      "/admin/user-doc-details?userId=$userId&fullName=${widget.fullName}&email=${widget.email}&docType=$docType",
    );
  }
}
