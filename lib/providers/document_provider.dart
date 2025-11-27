import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../controllers/document_controller.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentController _controller = DocumentController();

  List<Map<String, dynamic>> documents = [];
  bool loading = false;

  /// Load ALL documents for dashboard
  Future<void> loadDocuments(String uid) async {
    loading = true;
    notifyListeners();

    documents = await _controller.getUserDocuments(uid);

    loading = false;
    notifyListeners();
  }

  /// Get the status for UI (dashboard)
  String getStatusForDoc(String docType) {
    final doc = documents.firstWhere(
          (d) => d["docType"] == docType,
      orElse: () => {},
    );

    if (doc.isEmpty) return "missing";

    final now = DateTime.now();

    // Expiration logic
    if (doc["expiration"] != null) {
      final exp = doc["expiration"].toDate();

      if (exp.isBefore(now)) return "expired";
      if (exp.difference(now).inDays <= 30) return "near expiry";
    }

    return (doc["status"] ?? "missing").toString().toLowerCase();
  }

  /// Upload document (Web + Mobile)
  Future<String?> upload({
    required String userId,
    required String docType,
    Uint8List? webBytes,
    String? filename,
    File? mobileFile,
    DateTime? expiration,
  }) async {
    loading = true;
    notifyListeners();

    final error = await _controller.uploadDocument(
      uid: userId,
      docType: docType,
      webBytes: webBytes,
      filename: filename,
      mobilePath: mobileFile?.path,
      expiration: expiration,
    );

    await loadDocuments(userId);

    loading = false;
    notifyListeners();

    return error;
  }

  /// Get single document details
  Future<Map<String, dynamic>?> getDocument(String uid, String docType) {
    return _controller.getDocument(uid, docType);
  }

  /// Update status (admin usage)
  Future<void> updateStatus({
    required String uid,
    required String docType,
    required String status,
  }) async {
    await _controller.updateStatus(uid, docType, status);
    await loadDocuments(uid);
  }

  /// Delete document
  Future<void> deleteDocument(String uid, String docType) async {
    await _controller.deleteDocument(uid, docType);
    await loadDocuments(uid);
  }
}
