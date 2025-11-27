import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DocumentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Convert human-readable name to clean storage key
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

  // GET all documents
  Future<List<Map<String, dynamic>>> getUserDocuments(String uid) async {
    final snap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  // GET single document
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

  // UPLOAD document + metadata
  Future<String?> uploadDocument(
      String uid,
      String docType,
      File file,
      DateTime? expiration,
      ) async {
    try {
      final docKey = mapDocNameToKey(docType);
      final ext = file.path.split('.').last;

      // Firebase Storage upload
      final ref = _storage.ref().child(
        "users/$uid/documents/$docKey/file.$ext",
      );

      await ref.putFile(file);
      final fileUrl = await ref.getDownloadURL();

      // Firestore metadata
      await _firestore
          .collection("users")
          .doc(uid)
          .collection("documents")
          .doc(docKey)
          .set({
        "docType": docType,
        "docKey": docKey,
        "fileUrl": fileUrl,
        "status": "processing",
        "uploadedAt": FieldValue.serverTimestamp(),
        "expiration": expiration != null
            ? Timestamp.fromDate(expiration)
            : null,
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // UPDATE status
  Future<void> updateStatus(String uid, String docType, String status) async {
    final key = mapDocNameToKey(docType);

    await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .doc(key)
        .update({"status": status});
  }

  // DELETE document
  Future<void> deleteDocument(String uid, String docType) async {
    final key = mapDocNameToKey(docType);

    // Delete Firestore document
    await _firestore
        .collection("users")
        .doc(uid)
        .collection("documents")
        .doc(key)
        .delete();

    // Delete Storage file
    await _storage
        .ref("users/$uid/documents/$key/file")
        .delete()
        .catchError((_) {});
  }
}
