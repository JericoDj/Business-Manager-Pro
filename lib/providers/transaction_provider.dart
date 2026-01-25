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

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _companySubscription?.cancel();
    super.dispose();
  }
}
