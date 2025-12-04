import 'dart:io' show File;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/document_controller.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentController _controller = DocumentController();

  List<Map<String, dynamic>> documents = [];
  bool loading = false;

  /// Load ALL documents for dashboard
  Future<void> loadDocuments(String uid) async {
    String? userDocId = await _controller.findUserDocIdByUid(uid);
    loading = true;
    notifyListeners();

    documents = await _controller.getUserDocuments(userDocId );

    loading = false;
    notifyListeners();
  }

  Future<void> adminLoadUserDocuments({
    required String fullName,
    required String email,
  }) async {

    print(fullName);
    print(email);
    loading = true;
    notifyListeners();

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: fullName)
        .where("email", isEqualTo: email)
        .limit(1)
        .get();
    final data = snap.docs.first.data();
    print(data);


    if (snap.docs.isEmpty) {
      documents = [];
      loading = false;
      notifyListeners();
      return;
    }

    final userId = snap.docs.first.id;
    print(userId);
    print(userId);

    documents = await _controller.getUserDocuments(userId);
    print(documents);


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
    String? fullName,
    String? email,
    Uint8List? webBytes,
    String? filename,
    File? mobileFile,
    DateTime? expiration,
  }) async {
    loading = true;
    notifyListeners();

    print(userId);

    final uploadedDocument = await _controller.uploadUserDocument(
      userDocId: userId,
      docType: docType,
      webBytes: webBytes,
      filename: filename,
      mobilePath: mobileFile?.path,
      expiration: expiration,
    );

    await loadDocuments(userId);

    loading = false;
    final profile = GetStorage().read("profile");
    if(profile["role"] == "admin" || profile["role"] == "super_admin"){
      print(profile["role"]);
      await adminLoadUserDocuments(
        fullName: profile["name"],
        email: profile["email"],
      );
    }
    notifyListeners();

    return uploadedDocument;
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
