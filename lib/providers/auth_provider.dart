import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../repositories/authentication_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? currentUser;
  Map<String, dynamic>? currentUserProfile;
  bool initialized = false;

  bool isLoading = false;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

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
        out[key] =
            value.map((e) {
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

  Future<String?> forgotPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // LOAD USER PROFILE FROM FIRESTORE
  Future<void> loadUserProfile(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists) {
      final data = Map<String, dynamic>.from(doc.data()!);

      // Fetch company name from businesses collection
      final businessId = data['businessId'];
      if (businessId != null) {
        final bizSnap =
            await _firestore
                .collection("businesses")
                .where("companyCode", isEqualTo: businessId)
                .limit(1)
                .get();
        if (bizSnap.docs.isNotEmpty) {
          data['companyName'] =
              bizSnap.docs.first.data()['companyName'] ?? businessId;
        }
      }

      // SANITIZE TIMESTAMP
      final safeData = _sanitizeForStorage(data);

      currentUserProfile = safeData;
      _storage.write("profile", safeData);
      print(_storage.read("profile"));
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

  Future<String?> createBusinessAndAdmin({
    required String companyName,
    required String businessEmail,
    required String companyCode,
    required String adminName,
    required String adminPhone,
    required String adminAddress,
    required String adminBirthDate,
    required String password,
    String subscription = 'free',
  }) async {
    try {
      // 1️⃣ Check if email already exists (Auth)
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        businessEmail,
      );

      if (methods.isNotEmpty) return "This email already exists.";

      // 2️⃣ Check if company code is unique
      final existing =
          await _firestore
              .collection("businesses")
              .where("companyCode", isEqualTo: companyCode)
              .limit(1)
              .get();
      if (existing.docs.isNotEmpty) return "Company code already exists.";

      // 3️⃣ Register admin user in Firebase Auth
      final user = await _repo.register(businessEmail, password);
      if (user == null) return "Failed to create admin user.";

      currentUser = user;
      _storage.write("uid", user.uid);

      // 4️⃣ Create Admin Profile WITH FINAL businessId = companyCode
      final profile = {
        "uid": user.uid,
        "name": adminName,
        "phone": adminPhone,
        "email": businessEmail,
        "homeAddress": adminAddress,
        "dateOfBirth": adminBirthDate,
        "role": "super_admin",
        "businessId": companyCode, // final, no need to update later
        "companyName": companyName,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await _firestore.collection("users").doc(user.uid).set(profile);
      print("heres the profile");
      print(profile);
      print("heres the profile");
      // Save to local storage
      await loadUserProfile(user.uid);

      notifyListeners();
      print(currentUser);

      // 5️⃣ Create the business
      await _firestore.collection("businesses").add({
        "companyName": companyName,
        "businessEmail": businessEmail,
        "companyCode": companyCode,
        "subscription": {
          "plan": subscription,
          "status": "active",
          "updatedAt": FieldValue.serverTimestamp(),
        },
        "createdAt": FieldValue.serverTimestamp(),
      });

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
    required String role,
    required String companyCode,
  }) async {
    try {
      // ----------------------------------------------------
      // 1️⃣ CHECK IF COMPANY EXISTS
      // ----------------------------------------------------
      final companySnap =
          await _firestore
              .collection("businesses")
              .where("companyCode", isEqualTo: companyCode)
              .limit(1)
              .get();

      if (companySnap.docs.isEmpty) {
        return "Invalid company code.";
      }

      final companyId = companySnap.docs.first.id;

      // ----------------------------------------------------
      // 2️⃣ CHECK IF USER EXISTS UNDER THIS COMPANY
      // ----------------------------------------------------
      final existingUserSnap =
          await _firestore
              .collection("users")
              .where("businessId", isEqualTo: companyCode)
              .where("name", isEqualTo: name)
              .where("email", isEqualTo: email)
              .limit(1)
              .get();

      if (existingUserSnap.docs.isEmpty) {
        // ❌ DO NOT ALLOW REGISTRATION
        return "You are not registered under this company. Contact your admin.";
      }

      // ✔ User exists, upgrade their record
      final userDocRef = existingUserSnap.docs.first.reference;

      // ----------------------------------------------------
      // 3️⃣ REGISTER USER WITH FIREBASE AUTH
      // ----------------------------------------------------
      final user = await _repo.register(email, password);
      if (user == null) return "Registration failed.";

      currentUser = user;
      _storage.write("uid", user.uid);

      // ----------------------------------------------------
      // 4️⃣ UPDATE EXISTING USER DOCUMENT
      // ----------------------------------------------------
      final profileData = {
        "uid": user.uid,
        "name": name,
        "phone": phone,
        "email": email,
        "homeAddress": homeAddress,
        "dateOfBirth": dateOfBirth,
        "role": role,
        "businessId": companyCode,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await userDocRef.set(profileData, SetOptions(merge: true));

      // ----------------------------------------------------
      // 5️⃣ SAVE PROFILE LOCALLY
      // ----------------------------------------------------
      final savedDoc = await userDocRef.get();
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

  // UPLOAD PROFILE IMAGE
  Future<String?> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      if (currentUser == null) return "No user logged in";
      String uid = currentUser!.uid;

      // 1. Upload to Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child(
            "$uid.jpg",
          ); // Force jpg extension for consistency or use fileName extension

      // Upload raw data
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // 2. Update Firestore
      await _firestore.collection("users").doc(uid).update({"photoURL": url});

      // 3. Update Local State
      if (currentUserProfile != null) {
        currentUserProfile!["photoURL"] = url;
        _storage.write("profile", currentUserProfile);
        notifyListeners();
      }

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
