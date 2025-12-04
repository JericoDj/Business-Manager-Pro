import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> clients = [];
  bool isLoading = false;

  Future<void> fetchClients() async {
    isLoading = true;
    notifyListeners();

    final snap = await _firestore
        .collection("clients")
        .orderBy("createdAt", descending: true)
        .get();

    clients = snap.docs.map((d) {
      final data = d.data();
      data["id"] = d.id;
      return data;
    }).toList();

    isLoading = false;
    notifyListeners();
  }

  // -----------------------------
  // CREATE CLIENT
  // -----------------------------
  Future<String?> addClient({
    required String name,
    String? address,
    String? contact,
    String? email,
    int? age,
    String? notes,
  }) async {
    try {
      final docData = {
        "name": name,
        "address": address,
        "contact": contact,
        "email": email,
        "age": age,
        "notes": notes,
        "createdAt": FieldValue.serverTimestamp(),
      };

      // remove null values
      docData.removeWhere((key, value) => value == null);

      await _firestore.collection("clients").add(docData);
      await fetchClients();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // -----------------------------
  // UPDATE CLIENT
  // -----------------------------
  Future<String?> updateClient(
      String id, {
        required String name,
        String? address,
        String? contact,
        String? email,
        int? age,
        String? notes,
      }) async {
    try {
      final updatedData = {
        "name": name,
        "address": address,
        "contact": contact,
        "email": email,
        "age": age,
        "notes": notes,
      };

      updatedData.removeWhere((key, value) => value == null);

      await _firestore.collection("clients").doc(id).update(updatedData);
      await fetchClients();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // -----------------------------
  // DELETE CLIENT
  // -----------------------------
  Future<void> deleteClient(String id) async {
    await _firestore.collection("clients").doc(id).delete();
    await fetchClients();
  }
}
