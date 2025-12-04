import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/document_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDocs();
    });
  }

  Future<void> loadDocs() async {
    final docProvider = context.read<DocumentProvider>();

    await docProvider.adminLoadUserDocuments(
      fullName: widget.fullName,
      email: widget.email,
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Documents: ${widget.fullName}"),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Required Documents",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, i) {
                  final title = documents[i];
                  final status = docProvider.getStatusForDoc(title).toLowerCase();

                  return _buildDocumentTile(title, status);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String title, String status) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          "Status: $status",
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Fetch UID again for the detail screen
          final snap = await FirebaseFirestore.instance
              .collection("users")
              .where("name", isEqualTo: widget.fullName)
              .where("email", isEqualTo: widget.email)
              .limit(1)
              .get();

          if (snap.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User record not found"))
            );
            return;
          }

          final userId = snap.docs.first.id;
          print(widget.fullName);

          context.push(
            "/admin/user-doc-details?userId=$userId&fullName=${widget.fullName}&email=${widget.email}&docType=$title",
          );
        },
      ),
    );
  }
}

