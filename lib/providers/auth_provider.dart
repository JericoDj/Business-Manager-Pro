import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/authentication_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? currentUser;
  Map<String, dynamic>? currentUserProfile;
  bool initialized = false;

  AuthProvider() {
    _initialize();
  }

  // --- SANITIZER: Remove Timestamp and replace with ISO string ---
  Map<String, dynamic> _sanitizeForStorage(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      if (value is Timestamp) {
        out[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        out[key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        out[key] = _sanitizeForStorage(value);
      } else if (value is List) {
        out[key] = value.map((e) {
          if (e is Timestamp) return e.toDate().toIso8601String();
          if (e is DateTime) return e.toIso8601String();
          if (e is Map<String, dynamic>) return _sanitizeForStorage(e);
          return e;
        }).toList();
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  // INITIALIZE PROVIDER
  void _initialize() async {
    String? savedUid = _storage.read("uid");

    if (savedUid != null) {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await loadUserProfile(currentUser!.uid);
      }
    }

    // WATCH AUTH CHANGES
    _repo.authStateChanges.listen((user) async {
      currentUser = user;

      if (user == null) {
        _storage.erase();
        currentUserProfile = null;
      } else {
        _storage.write("uid", user.uid);
        await loadUserProfile(user.uid);
      }

      notifyListeners();
    });

    initialized = true;
  }

  // LOAD USER PROFILE FROM FIRESTORE
  Future<void> loadUserProfile(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();

    if (doc.exists) {
      final data = Map<String, dynamic>.from(doc.data()!);


      // SANITIZE TIMESTAMP
      final safeData = _sanitizeForStorage(data);

      currentUserProfile = safeData;
      _storage.write("profile", safeData);
    }
  }

  // LOGIN USER
  Future<String?> login(String email, String password) async {
    try {
      final user = await _repo.login(email, password);
      currentUser = user;

      if (user != null) {
        _storage.write("uid", user.uid);
        await loadUserProfile(user.uid);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // REGISTER USER AND SAVE PROFILE
  Future<String?> registerUser({
    required String name,
    required String phone,
    required String email,
    required String homeAddress,
    required String dateOfBirth,
    required String password,
  }) async {
    try {
      final user = await _repo.register(email, password);
      if (user == null) return "Registration failed.";

      currentUser = user;
      _storage.write("uid", user.uid);

      // Firestore profile
      final profileData = {
        "uid": user.uid,
        "name": name,
        "phone": phone,
        "email": email,
        "homeAddress": homeAddress,
        "dateOfBirth": dateOfBirth,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await _firestore.collection("users").doc(user.uid).set(profileData);

      // Fetch and sanitize stored doc (to get real Timestamp)
      final savedDoc = await _firestore.collection("users").doc(user.uid).get();
      final savedData = Map<String, dynamic>.from(savedDoc.data()!);

      final safeData = _sanitizeForStorage(savedData);

      currentUserProfile = safeData;
      _storage.write("profile", safeData);

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _repo.logout();
    _storage.erase();
    currentUser = null;
    currentUserProfile = null;
    notifyListeners();
  }

  bool get isLoggedIn => currentUser != null;
}
