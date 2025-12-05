// UPDATED FULL FILE — READY TO PASTE

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

  // ------------------------------------
  // CHANGE STATUS DIALOG
  // ------------------------------------
  void _openStatusDialog() {
    final docProvider = context.read<DocumentProvider>();
    final options = [
      "approved",
      "processing",
      "rejected",
      "expired",
      "near expiry",
      "missing",
      "verified",
    ];

    String selected = options.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialog) {
          return AlertDialog(
            title: const Text("Change Document Status"),
            content: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: options.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) => setDialog(() => selected = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  final result = await docProvider.updateDocumentStatus(
                    userId: widget.userId,
                    docType: widget.docType,
                    status: selected,
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            result ?? "Status updated to ${selected.toUpperCase()}")),
                  );

                  setState(() {});
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------
  // PICK FILE
  // ------------------------------------
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
    final provider = context.watch<DocumentProvider>();

    final doc = provider.documents.firstWhere(
          (d) => d["docType"] == widget.docType,
      orElse: () => {},
    );

    final docData = doc.isEmpty ? null : doc;

    final now = DateTime.now();
    String status = docData?["status"] ?? "missing";

    if (docData?["expiration"] != null) {
      final exp = docData!["expiration"].toDate();

      if (exp.isBefore(now)) {
        status = "expired";
      } else if (exp.difference(now).inDays <= 30) {
        status = "near expiry";
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
              _buildStatusBox(status),

              const SizedBox(height: 20),
              const Text("Uploaded File",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              InkWell(
                onTap: docData?["fileUrl"] != null
                    ? () => _openView(docData!["fileUrl"])
                    : null,
                child: _preview(docData),
              ),

              const SizedBox(height: 25),

              if (expiryDocs.contains(widget.docType))
                _buildExpirationUI(),

              const SizedBox(height: 25),
              _buildUploadUI(provider),

              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _openStatusDialog,
                child: const Text("Change Status"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------
  // EXPIRATION UI
  // ------------------------------------
  Widget _buildExpirationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Expiration Date",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _openExpirationPicker,
          child: Text(
            expirationDate == null
                ? "Select Expiration"
                : "Expires: ${_monthName(expirationDate!.month)} ${expirationDate!.year}",
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton(

          onPressed: expirationDate == null ? null : _saveExpiration,
          child: const Text("Save Expiration"),
        ),
      ],
    );
  }

  void _openExpirationPicker() {
    final now = DateTime.now();
    int month = expirationDate?.month ?? now.month;
    int year = expirationDate?.year ?? now.year;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialog) {
          return AlertDialog(
            title: const Text("Select Expiration Date"),
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
                  onChanged: (v) => setDialog(() => month = v!),
                ),
                DropdownButton<int>(
                  value: year,
                  items: List.generate(
                    15,
                        (i) => DropdownMenuItem(
                      value: now.year + i,
                      child: Text("${now.year + i}"),
                    ),
                  ),
                  onChanged: (v) => setDialog(() => year = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    expirationDate = DateTime(year, month, 1);
                  });
                  Navigator.pop(dialogContext);
                },
                child: const Text("Set"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveExpiration() async {
    await context.read<DocumentProvider>().updateDocumentExpiration(
      userId: widget.userId,
      docType: widget.docType,
      expiration: expirationDate!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expiration updated")),
    );

    setState(() {});
  }

  // ------------------------------------
  // UPLOAD UI
  // ------------------------------------
  Widget _buildUploadUI(DocumentProvider provider) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: pickFile,
          icon: const Icon(Icons.upload),
          label: Text(
            filename ?? "Select File",
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: (mobileFile == null && webBytes == null)
              ? null
              : () async {
            final result = await provider.upload(
              fullName: widget.fullName,
              email: widget.email,
              userId: widget.userId,
              docType: widget.docType,
              mobileFile: mobileFile,
              webBytes: webBytes,
              filename: filename,
              expiration: expirationDate,
            );

            if (result != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(result)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("File uploaded")),
              );

              // Auto-set status after upload
              await provider.updateDocumentStatus(
                userId: widget.userId,
                docType: widget.docType,
                status: "processing",
              );

              setState(() {
                mobileFile = null;
                webBytes = null;
              });
            }
          },
          child: provider.loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Upload"),
        )
      ],
    );
  }

  // ------------------------------------
  // PREVIEW UI
  // ------------------------------------
  Widget _preview(Map<String, dynamic>? docData) {
    if (mobileFile != null) {
      return _previewItem(mobileFile!.path.split("/").last, "Local File");
    }

    if (docData?["fileUrl"] == null) {
      return _previewItem("No file uploaded", "");
    }

    final url = docData!["fileUrl"];
    final fileName = url.toString().split("%2F").last.split("?").first;

    return _previewItem(fileName, "Tap to view");
  }

  Widget _previewItem(String title, String subtitle) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------
  // VIEW FILE
  // ------------------------------------
  void _openView(String url) {
    final bool isPdf = url.toLowerCase().endsWith(".pdf");

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: isPdf ? _pdfViewer(url) : _imageViewer(url),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _imageViewer(String url) {
    return PhotoView(
      imageProvider: NetworkImage(url),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _pdfViewer(String url) {
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
    final file = File("${dir.path}/temp_view.pdf");
    await file.writeAsBytes(data.bodyBytes);
    return file;
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
}
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