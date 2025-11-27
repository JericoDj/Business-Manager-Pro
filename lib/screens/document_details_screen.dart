import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';

class DocumentDetailsScreen extends StatefulWidget {
  final String docType;

  const DocumentDetailsScreen({super.key, required this.docType});

  @override
  State<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  File? pickedFile;
  Map<String, dynamic>? docData;
  bool loading = true;
  DateTime? expirationDate;

  final expiryDocs = [
    "License ID",
    "CPR Certification",
    "Driver’s License",
    "Physical",
    "TB Test Result"
  ];

  @override
  void initState() {
    super.initState();
    loadDoc();
  }

  Future<void> loadDoc() async {
    final auth = context.read<AuthProvider>();
    final docProvider = context.read<DocumentProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null) return;

    final data = await docProvider.getDocument(uid, widget.docType);

    if (!mounted) return;

    setState(() {
      docData = data;
      expirationDate = data?["expiration"]?.toDate();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final docProvider = context.watch<DocumentProvider>();

    final uid = auth.currentUser?.uid;

    /// --------------------------
    /// FIXED STATUS LOGIC
    /// --------------------------
    final now = DateTime.now();
    String status = "Missing";

    if (docData != null) {
      status = docData!["status"] ?? "Missing";

      if (docData?["expiration"] != null) {
        final exp = docData!["expiration"].toDate();

        if (exp.isBefore(now)) {
          status = "Expired";
        } else if (exp.isBefore(now.add(const Duration(days: 30)))) {
          status = "Near Expiry";
        }
      }
    }

    final isApproved = status.toLowerCase() == "approved";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docType),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: uid == null
          ? const Center(child: Text("User not logged in"))
          : loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// STATUS HEADER
              const Text(
                "Document Status",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              _buildStatusBox(status),

              const SizedBox(height: 20),

              /// FILE PREVIEW SECTION
              const Text(
                "Uploaded File",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: docData?["fileUrl"] != null
                    ? () => _openFileDialog(docData!["fileUrl"])
                    : null,
                child: _buildDocumentPreview(),
              ),

              const SizedBox(height: 20),

              /// EXPIRATION SECTION
              if (_requiresExpiration(widget.docType))
                _buildExpirationSelector(),

              const SizedBox(height: 20),

              /// VERIFIED → LOCK UPLOAD
              if (isApproved)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "This document is already VERIFIED.\nRe-uploading is disabled.",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ),

              if (!isApproved) ...[
                /// SELECT FILE BUTTON
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform
                        .pickFiles(withData: true);

                    if (result != null) {
                      final file = result.files.single;

                      if (file.path != null) {
                        pickedFile = File(file.path!);
                      } else {
                        final temp = File(
                            "/tmp/${file.name.replaceAll(' ', '_')}");
                        await temp.writeAsBytes(file.bytes!);
                        pickedFile = temp;
                      }

                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select File"),
                ),

                const SizedBox(height: 10),

                /// UPLOAD BUTTON
                ElevatedButton(
                  onPressed: pickedFile == null
                      ? null
                      : () async {
                    final error = await docProvider.upload(
                      userId: uid,
                      type: widget.docType,
                      file: pickedFile!,
                      expiration: expirationDate,
                    );

                    if (!mounted) return;

                    if (error != null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              "File uploaded. Status: PROCESSING"),
                        ),
                      );
                      loadDoc();
                    }
                  },
                  child: docProvider.loading
                      ? const CircularProgressIndicator()
                      : const Text("Upload"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------------------------------------------
  /// STATUS BOX (UPDATED COLORS + NEW STATES)
  /// ---------------------------------------------------
  Widget _buildStatusBox(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case "approved":
        color = Colors.green.withOpacity(0.25);
        break;
      case "rejected":
        color = Colors.red.withOpacity(0.25);
        break;
      case "processing":
        color = Colors.orange.withOpacity(0.25);
        break;
      case "expired":
        color = Colors.redAccent.withOpacity(0.25);
        break;
      case "near expiry":
        color = Colors.amber.withOpacity(0.25);
        break;
      default:
        color = Colors.grey.withOpacity(0.25);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color,
      ),
      child: Text(
        status.toLowerCase(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// ---------------------------------------------------
  /// PREVIEW BOX
  /// ---------------------------------------------------
  Widget _buildDocumentPreview() {
    if (pickedFile != null) {
      return _previewBox(
        pickedFile!.path.split('/').last,
        "Local File (Replace)",
      );
    }

    if (docData == null || docData?["fileUrl"] == null) {
      return _previewBox("No file uploaded", "");
    }

    final fileUrl = docData!["fileUrl"];
    final fileName = fileUrl.toString().split("%2F").last.split("?").first;

    return _previewBox(fileName, "Tap to view");
  }

  Widget _previewBox(String text, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  bool _requiresExpiration(String docType) {
    return expiryDocs.contains(docType);
  }

  /// ---------------------------------------------------
  /// EXPIRATION SELECTOR
  /// ---------------------------------------------------
  Widget _buildExpirationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Expiration (Month & Year)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

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
                        onChanged: (v) {
                          setState(() => selectedMonth = v!);
                        },
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
                        onChanged: (v) {
                          setState(() => selectedYear = v!);
                        },
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
                        final lastDay = DateTime(
                            selectedYear, selectedMonth + 1, 0);

                        setState(() {
                          expirationDate = lastDay;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            expirationDate == null
                ? "Select Expiration"
                : "Expires: ${_monthName(expirationDate!.month)} ${expirationDate!.year}",
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const names = [
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
    return names[m - 1];
  }

  /// IMAGE VIEWER
  Widget _buildImageViewer(String url) {
    return PhotoView(
      imageProvider: NetworkImage(url),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (_, __) =>
      const Center(child: CircularProgressIndicator()),
    );
  }

  /// PDF VIEWER
  Widget _buildPdfViewer(String url) {
    return FutureBuilder<File>(
      future: _downloadPDF(url),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return PDFView(
          filePath: snapshot.data!.path,
          swipeHorizontal: true,
          nightMode: true,
        );
      },
    );
  }

  Future<File> _downloadPDF(String url) async {
    final bytes = await http.get(Uri.parse(url));
    final tempDir = await getTemporaryDirectory();
    final tempFile = File("${tempDir.path}/temp_doc.pdf");

    await tempFile.writeAsBytes(bytes.bodyBytes);
    return tempFile;
  }

  void _openFileDialog(String url) {
    final isPDF = url.toLowerCase().endsWith(".pdf");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: isPDF
                  ? _buildPdfViewer(url)
                  : _buildImageViewer(url),
            ),

            Positioned(
              right: 10,
              top: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
