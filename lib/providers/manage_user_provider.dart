import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ManageUserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  bool isLoading = false;

  ManageUserProvider() {
    _autoLoadUsers(); // 🚀 auto-load on creation
  }

  String get companyId {
    final profile = GetStorage().read("profile") as Map<String, dynamic>?;
    return profile?["businessId"] ?? "";
  }

  // 🚀 AUTO LOAD USERS WHEN PROVIDER IS CREATED
  void _autoLoadUsers() {
    Future.microtask(() async {
      await fetchUsers();
    });
  }

  // 🔥 Fetch all users belonging to same company
  Future<void> fetchUsers() async {
    if (companyId.isEmpty) return;

    isLoading = true;
    notifyListeners();

    final snap =
        await _firestore
            .collection("users")
            .where("businessId", isEqualTo: companyId)
            .get();

    // Store full data including docId
    // AND fetch document counts in parallel
    users = await Future.wait(
      snap.docs.map((d) async {
        final data = d.data();
        data["docId"] = d.id; // store document ID

        // Fetch document count
        final docSnap =
            await _firestore
                .collection("users")
                .doc(d.id)
                .collection("documents")
                .count()
                .get();

        data["documentCount"] = docSnap.count;

        return data;
      }),
    );

    print(users);

    isLoading = false;
    notifyListeners();
  }

  // 🔥 Add new user — NO FirebaseAuth
  Future<String?> addUser({
    required String name,
    required String phone,
    required String email,
    required String homeAddress,
    required String birthDate,
  }) async {
    try {
      if (companyId.isEmpty) return "Company ID missing.";

      await _firestore.collection("users").add({
        "uid": null, // No login account
        "name": name,
        "phone": phone,
        "email": email,
        "homeAddress": homeAddress,
        "dateOfBirth": birthDate,
        "role": null, // Offline user
        "businessId": companyId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await fetchUsers(); // refresh list
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // 🔥 Update user
  Future<void> updateUser(String docId, Map<String, dynamic> updates) async {
    await _firestore.collection("users").doc(docId).update(updates);
    await fetchUsers();
  }

  // 🔥 Delete user
  Future<void> deleteUser(String docId) async {
    await _firestore.collection("users").doc(docId).delete();
    await fetchUsers();
  }
}
