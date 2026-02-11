import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyDocumentModel {
  final String id;
  final String title;
  final String status;
  final DateTime? expiryDate;
  final String fileUrl;
  final DateTime createdAt;
  final String fileName;

  CompanyDocumentModel({
    required this.id,
    required this.title,
    required this.status,
    this.expiryDate,
    required this.fileUrl,
    required this.createdAt,
    required this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'fileUrl': fileUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fileName': fileName,
    };
  }

  factory CompanyDocumentModel.fromMap(Map<String, dynamic> map) {
    return CompanyDocumentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      status: map['status'] ?? '',
      expiryDate:
          map['expiryDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
              : null,
      fileUrl: map['fileUrl'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      fileName: map['fileName'] ?? '',
    );
  }

  factory CompanyDocumentModel.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return CompanyDocumentModel(
      id: doc.id,
      title: map['title'] ?? '',
      status: map['status'] ?? '',
      expiryDate:
          map['expiryDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
              : null,
      fileUrl: map['fileUrl'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      fileName: map['fileName'] ?? '',
    );
  }
}
