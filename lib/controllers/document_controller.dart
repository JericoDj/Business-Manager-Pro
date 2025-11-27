import 'dart:io' show File;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DocumentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Convert name → consistent storage key
  String mapDocNameToKey(String name) {
    return name
        .toLowerCase()
        .replaceAll("’", "")
        .replaceAll("'", "")
        .replaceAll("-", " ")
        .replaceAll("/", " ")
        .replaceAll("(", "")
        .replaceAll(")", "")
        .replaceAll("  ", " ")
        .trim()
        .replaceAll(" ", "_");
  }

  Future<List<Map<String, dynamic>>> getUserDocuments(String uid) async {
    final snap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  /// Get a single document
  Future<Map<String, dynamic>?> getDocument(String uid, String docType) async {
    final key = mapDocNameToKey(docType);

    final doc = await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .doc(key)
        .get();

    return doc.exists ? doc.data() : null;
  }

  /// Upload document (supports mobile AND web)
  Future<String?> uploadDocument({
    required String uid,
    required String docType,
    Uint8List? webBytes,
    String? filename,
    String? mobilePath,
    DateTime? expiration,
  }) async {
    try {
      final key = mapDocNameToKey(docType);
      final ext = filename?.split('.').last ?? "jpg";

      final ref = _storage.ref("users/$uid/documents/$key/file.$ext");

      /// Upload file depending on platform
      if (webBytes != null) {
        await ref.putData(webBytes);
      } else if (mobilePath != null) {
        final file = File(mobilePath);
        await ref.putFile(file);
      } else {
        return "No file data provided";
      }

      /// Force correct Firebase Storage bucket download URL
      final downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection("users")
          .doc(uid)
          .collection("documents")
          .doc(key)
          .set({
        "docType": docType,
        "fileUrl": downloadUrl,
        "status": "processing",
        "uploadedAt": FieldValue.serverTimestamp(),
        "expiration": expiration,
      }, SetOptions(merge: true));

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  /// Update status
  Future<void> updateStatus(String uid, String docType, String status) async {
    final key = mapDocNameToKey(docType);

    await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .doc(key)
        .update({"status": status});
  }

  /// Delete document
  Future<void> deleteDocument(String uid, String docType) async {
    final key = mapDocNameToKey(docType);

    // Delete Firestore metadata
    await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .doc(key)
        .delete();

    // Delete file from Storage
    await _storage
        .ref("users/$uid/documents/$key")
        .delete()
        .catchError((_) {});
  }
}
