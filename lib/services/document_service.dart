import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document_model.dart';

class DocumentService {
  final storage = FirebaseStorage.instance;
  final firestore = FirebaseFirestore.instance;

  Future<void> uploadDocument({
    required String userId,
    required String type,
    required File file,
    DateTime? expiration,
  }) async {
    final ref = storage
        .ref()
        .child('users/$userId/documents/$type/${DateTime.now()}.jpg');

    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();

    final doc = DocumentModel(
      type: type,
      fileUrl: url,
      expiration: expiration,
      uploadedAt: DateTime.now(),
    );

    await firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(type)
        .set(doc.toJson());
  }
}
