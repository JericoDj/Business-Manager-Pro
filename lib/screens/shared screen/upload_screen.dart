import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';

class UploadScreen extends StatefulWidget {
  final String docType;

  const UploadScreen({super.key, required this.docType});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? mobileFile;
  Uint8List? webBytes;
  String? filename;

  DateTime? expirationDate;

  final expiryDocs = [
    "License ID",
    "CPR Certification",
    "Driver’s License",
    "Physical",
    "TB Test Result",
  ];

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null) return;

    final file = result.files.single;

    filename = file.name;

    if (kIsWeb) {
      webBytes = file.bytes;
    } else {
      mobileFile = File(file.path!);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final docProvider = context.watch<DocumentProvider>();

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Upload ${widget.docType}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select File",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text("Choose File"),
            ),

            const SizedBox(height: 12),

            if (filename != null)
              Text(
                "Selected: $filename",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

            const SizedBox(height: 25),

            if (expiryDocs.contains(widget.docType))
              _buildExpirationSelector(),

            const Spacer(),

            ElevatedButton(
              onPressed: (mobileFile == null && webBytes == null)
                  ? null
                  : () async {
                final error = await docProvider.upload(
                  userId: uid,
                  docType: widget.docType,
                  mobileFile: mobileFile,
                  webBytes: webBytes,
                  filename: filename,
                  expiration: expirationDate,
                );

                if (!mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Upload successful — Processing")),
                  );
                  Navigator.pop(context);
                }
              },
              child: docProvider.loading
                  ? const CircularProgressIndicator()
                  : const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Expiration Date",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: () async {
            final now = DateTime.now();
            int selectedMonth = expirationDate?.month ?? now.month;
            int selectedYear = expirationDate?.year ?? now.year;

            await showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text("Select Expiration"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(
                          12,
                              (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_monthName(i + 1)),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => selectedMonth = v!),
                      ),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(
                          20,
                              (i) => DropdownMenuItem(
                            value: now.year + i,
                            child: Text("${now.year + i}"),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => selectedYear = v!),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        expirationDate =
                            DateTime(selectedYear, selectedMonth, 28);
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    )
                  ],
                );
              },
            );
          },
          child: Text(
            expirationDate == null
                ? "Select Expiration"
                : "Expires: ${_monthName(expirationDate!.month)} "
                "${expirationDate!.year}",
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const list = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return list[m - 1];
  }
}
