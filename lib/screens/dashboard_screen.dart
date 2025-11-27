import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final auth = context.read<AuthProvider>();
    final docProvider = context.read<DocumentProvider>();

    final uid = auth.currentUser?.uid;
    if (uid != null) {
      await docProvider.loadDocuments(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final docProvider = context.watch<DocumentProvider>();
    final box = GetStorage();

    final profile = box.read("profile") as Map?;
    final fullName = profile?["name"] ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              auth.logout();
              context.go("/login");
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $fullName",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Required Documents",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, i) {
                  final title = documents[i];

                  /// ALWAYS LOWERCASE
                  final status = docProvider.getStatusForDoc(title).toLowerCase();

                  return _buildDocItem(context, title, status);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(BuildContext context, String title, String status) {
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
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          "status: $status", // LOWERCASE display
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push("/document-details?docType=$title");
        },
      ),
    );
  }
}
