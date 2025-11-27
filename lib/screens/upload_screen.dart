import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? selectedFile;
  DateTime? expiration;

  final docs = [
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

  String selectedDoc = "Resume";

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final auth = context.read<AuthProvider>();

    final userId = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Document")),
      body: userId == null
          ? const Center(child: Text("User not logged in"))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // DOCUMENT DROPDOWN
            DropdownButton<String>(
              value: selectedDoc,
              isExpanded: true,
              items: docs
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => selectedDoc = v!),
            ),

            const SizedBox(height: 20),

            // CHOOSE FILE BUTTON
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    selectedFile = File(result.files.single.path!);
                  });
                }
              },
              child: const Text("Choose File"),
            ),

            // SHOW FILENAME
            if (selectedFile != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  selectedFile!.path.split('/').last,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

            // EXPIRATION DATE PICKER
            if (_hasExpiration(selectedDoc)) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      expiration = date;
                    });
                  }
                },
                child: Text(
                  expiration == null
                      ? "Select Expiration Date"
                      : "Expires: ${expiration!.month}/${expiration!.day}/${expiration!.year}",
                ),
              ),
            ],

            const SizedBox(height: 20),

            // UPLOAD BUTTON
            ElevatedButton(
              onPressed: docProvider.loading || selectedFile == null
                  ? null
                  : () async {
                final error = await docProvider.upload(
                  userId: userId,
                  type: selectedDoc,
                  file: selectedFile!,
                  expiration: expiration,
                );

                if (!mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Upload successful — awaiting review"),
                    ),
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

  bool _hasExpiration(String doc) {
    return [
      "License ID",
      "CPR Certification",
      "Driver’s License",
    ].contains(doc);
  }
}
