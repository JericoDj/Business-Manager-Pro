import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String businessId;
  final String planId;
  final String status; // 'pending', 'completed', 'failed', 'canceled'
  final double amount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? polarCheckoutId;

  TransactionModel({
    required this.id,
    required this.businessId,
    required this.planId,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.updatedAt,
    this.polarCheckoutId,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      planId: data['planId'] ?? '',
      status: data['status'] ?? 'pending',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      polarCheckoutId: data['polarCheckoutId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'planId': planId,
      'status': status,
      'amount': amount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'polarCheckoutId': polarCheckoutId,
    };
  }
}
