import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/company_document_model.dart';

class CompanyDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'company_documents';

  // Upload document and save metadata
  Future<void> uploadDocument({
    required File file,
    required String title,
    required String status,
    DateTime? expiryDate,
  }) async {
    try {
      final String fileName = path.basename(file.path);
      final String storagePath =
          'company_documents/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Upload to Storage
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String fileUrl = await snapshot.ref.getDownloadURL();

      // Create document ID
      final String docId = _firestore.collection(_collectionPath).doc().id;

      final doc = CompanyDocumentModel(
        id: docId,
        title: title,
        status: status,
        expiryDate: expiryDate,
        fileUrl: fileUrl,
        createdAt: DateTime.now(),
        fileName: fileName,
      );

      // Save to Firestore
      await _firestore.collection(_collectionPath).doc(docId).set(doc.toMap());
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Get stream of documents
  Stream<List<CompanyDocumentModel>> getDocuments() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CompanyDocumentModel.fromSnapshot(doc))
              .toList();
        });
  }

  // Delete document
  Future<void> deleteDocument(String id, String fileUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection(_collectionPath).doc(id).delete();

      // Delete from Storage
      // We can try to extract the path from the URL, or if we had stored the storage path it would be easier.
      // For now, let's try to get the reference from the URL.
      try {
        final Reference ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      } catch (e) {
        print('Error deleting file from storage: $e');
        // Continue event if storage delete fails to ensure db consistency
      }
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
