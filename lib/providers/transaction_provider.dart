import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TransactionModel? _currentTransaction;
  StreamSubscription<DocumentSnapshot>? _transactionSubscription;
  StreamSubscription<DocumentSnapshot>? _companySubscription;

  TransactionModel? get currentTransaction => _currentTransaction;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String> createTransaction({
    required String businessId,
    required String planId,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1️⃣ Create document reference FIRST
      final docRef = _firestore.collection('transactions').doc();

      // 2️⃣ Write transaction
      await docRef.set({
        "transactionId": docRef.id,
        "businessId": businessId,
        "planId": planId,
        "status": "pending",
        "amount": amount,
        "currency": "usd",
        "createdAt": FieldValue.serverTimestamp(),
        "completedAt": null,
      });

      // 3️⃣ Listen for updates
      _listenToTransaction(docRef.id);

      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Cancel transaction (user changed mind during verification)
  Future<void> cancelTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Logic for stream update will be handled by the listener
    } catch (e) {
      print("Error cancelling transaction: $e");
      rethrow;
    }
  }

  void _listenToTransaction(String transactionId) {
    _transactionSubscription?.cancel();
    _transactionSubscription = _firestore
        .collection('transactions')
        .doc(transactionId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            _currentTransaction = TransactionModel.fromFirestore(snapshot);
            notifyListeners();
          }
        });
  }

  // Clear current transaction (e.g., when dialog closes)
  void clearTransaction() {
    _transactionSubscription?.cancel();
    _currentTransaction = null;
    notifyListeners();
  }

  // Poll for completion (Wait up to 3 minutes)
  Future<bool> waitForCompletion(String transactionId) async {
    int attempts = 0;
    const maxAttempts = 90; // 60 * 3s = 15 minutes

    while (attempts < maxAttempts) {
      try {
        final doc =
            await _firestore
                .collection('transactions')
                .doc(transactionId)
                .get();
        if (doc.exists) {
          final data = doc.data();
          final status = data?['status'];

          print("Transaction status: $status");
          print("Transaction data: $data");

          if (status == 'completed') {
            return true;
          }
          if (status == 'failed' || status == 'cancelled') {
            return false;
          }
        }
      } catch (e) {
        print("Polling error: $e");
      }

      await Future.delayed(const Duration(seconds: 10));
      attempts++;
    }

    return false; // Timeout
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _companySubscription?.cancel();
    super.dispose();
  }
}
