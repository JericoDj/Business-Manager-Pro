import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/document_provider.dart';

class AdminUserDocumentDetailsScreen extends StatefulWidget {
  final String userId;
  final String docType;
  final String fullName;
  final String email;

  const AdminUserDocumentDetailsScreen({
    super.key,
    required this.userId,
    required this.docType,
    required this.fullName,
    required this.email,
  });

  @override
  State<AdminUserDocumentDetailsScreen> createState() =>
      _AdminUserDocumentDetailsScreenState();
}

class _AdminUserDocumentDetailsScreenState
    extends State<AdminUserDocumentDetailsScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadExpiration();
  }

  void _loadExpiration() {
    final docs = context.read<DocumentProvider>();

    final doc = docs.documents.firstWhere(
          (d) => d["docType"] == widget.docType,
      orElse: () => {},
    );

    expirationDate = doc["expiration"]?.toDate();
  }

  Future<void> pickFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null) return;

    final file = picked.files.single;
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
    final docProvider = context.watch<DocumentProvider>();

    // Get live document from provider
    final doc = docProvider.documents.firstWhere(
          (d) => d["docType"] == widget.docType,
      orElse: () => {},
    );

    final docData = doc.isEmpty ? null : doc;

    final now = DateTime.now();
    String status = "missing";

    if (docData != null) {
      status = docData["status"]?.toString().toLowerCase() ?? "missing";

      if (docData["expiration"] != null) {
        final exp = docData["expiration"].toDate();
        if (exp.isBefore(now)) {
          status = "expired";
        } else if (exp.difference(now).inDays <= 30) {
          status = "near expiry";
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.docType} (Admin)"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Document Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildStatusBox(status),

              const SizedBox(height: 20),
              const Text("Uploaded File",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),
              InkWell(
                onTap: docData?["fileUrl"] != null
                    ? () => _openFileDialog(docData!["fileUrl"])
                    : null,
                child: _buildPreviewBox(docData),
              ),

              const SizedBox(height: 20),

              if (expiryDocs.contains(widget.docType))
                _buildExpirationSelector(),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload),
                label: const Text("Select File"),
              ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed:
                (mobileFile == null && webBytes == null) ? null : () async {



                  final error = await docProvider.upload(
                    fullName: widget.fullName,
                    email: widget.email,
                    userId: widget.userId,
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
                      const SnackBar(content: Text("Uploaded")),
                    );

                    // Refresh expiration only
                    final updated = docProvider.documents.firstWhere(
                          (d) => d["docType"] == widget.docType,
                      orElse: () => {},
                    );

                    setState(() {
                      expirationDate = updated["expiration"]?.toDate();
                      mobileFile = null;
                      webBytes = null;
                    });
                  }
                },
                child: docProvider.loading
                    ? const CircularProgressIndicator()
                    : const Text("Upload"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------
  // STATUS BOX
  // -----------------------------------------------
  Widget _buildStatusBox(String status) {
    Color color;

    switch (status) {
      case "approved":
        color = Colors.green.withOpacity(0.25);
        break;
      case "processing":
        color = Colors.orange.withOpacity(0.25);
        break;
      case "rejected":
        color = Colors.red.withOpacity(0.25);
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
        status.toUpperCase(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // -----------------------------------------------
  // FILE PREVIEW
  // -----------------------------------------------
  Widget _buildPreviewBox(Map<String, dynamic>? docData) {
    if (mobileFile != null) {
      return _previewItem(mobileFile!.path.split("/").last, "Local File");
    }

    if (docData?["fileUrl"] == null) {
      return _previewItem("No file uploaded", "");
    }

    final url = docData!["fileUrl"];
    final name = url.toString().split("%2F").last.split("?").first;

    return _previewItem(name, "Tap to view");
  }

  Widget _previewItem(String title, String subtitle) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------
  // EXPIRATION PICKER
  // -----------------------------------------------
  Widget _buildExpirationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Expiration (Month / Year)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _openExpirationDialog,
          child: Text(
            expirationDate == null
                ? "Select Expiration"
                : "Expires: ${_monthName(expirationDate!.month)} ${expirationDate!.year}",
          ),
        ),
      ],
    );
  }

  void _openExpirationDialog() {
    final now = DateTime.now();
    int month = expirationDate?.month ?? now.month;
    int year = expirationDate?.year ?? now.year;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Select Expiration"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: month,
                  items: List.generate(
                    12,
                        (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_monthName(i + 1)),
                    ),
                  ),
                  onChanged: (v) => setStateDialog(() => month = v!),
                ),
                DropdownButton<int>(
                  value: year,
                  items: List.generate(
                    20,
                        (i) => DropdownMenuItem(
                      value: now.year + i,
                      child: Text("${now.year + i}"),
                    ),
                  ),
                  onChanged: (v) => setStateDialog(() => year = v!),
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
                  setState(() {
                    expirationDate = DateTime(year, month, 28);
                  });
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
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

  // -----------------------------------------------
  // FILE VIEW (View PDF / Image)
  // -----------------------------------------------
  void _openFileDialog(String url) {
    final isPdf = url.toLowerCase().endsWith(".pdf");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: isPdf ? _buildPdfViewer(url) : _buildImageViewer(url),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer(String url) {
    return PhotoView(
      imageProvider: NetworkImage(url),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _buildPdfViewer(String url) {
    return FutureBuilder<File>(
      future: _downloadPDF(url),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return PDFView(filePath: snap.data!.path);
      },
    );
  }

  Future<File> _downloadPDF(String url) async {
    final data = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/temp_admin.pdf");
    await file.writeAsBytes(data.bodyBytes);
    return file;
  }
}
