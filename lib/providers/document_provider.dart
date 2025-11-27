import 'dart:io';
import 'package:flutter/material.dart';
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

  /// Get status of a single document (Dashboard)
  String getStatusForDoc(String docType) {
    final doc = documents.firstWhere(
          (d) => d["docType"] == docType,
      orElse: () => {},
    );

    if (doc.isEmpty) return "Missing";

    // Handle expiration dates
    if (doc.containsKey("expiration") && doc["expiration"] != null) {
      final exp = doc["expiration"].toDate();
      final now = DateTime.now();

      if (exp.isBefore(now)) return "Expired";

      // Within 30 days
      if (exp.difference(now).inDays <= 30) return "Near Expiry";
    }

    return doc["status"] ?? "Missing";
  }

  /// Upload (or replace)
  Future<String?> upload({
    required String userId,
    required String type,
    required File file,
    DateTime? expiration,
  }) async {
    loading = true;
    notifyListeners();

    final error = await _controller.uploadDocument(
      userId,
      type,
      file,
      expiration,
    );

    await loadDocuments(userId);

    loading = false;
    notifyListeners();

    return error;
  }

  Future<Map<String, dynamic>?> getDocument(String uid, String docType) async {
    return await _controller.getDocument(uid, docType);
  }

  Future<void> updateStatus({
    required String uid,
    required String docType,
    required String status,
  }) async {
    await _controller.updateStatus(uid, docType, status);
    await loadDocuments(uid);
  }

  Future<void> deleteDocument(String uid, String docType) async {
    await _controller.deleteDocument(uid, docType);
    await loadDocuments(uid);
  }
}
