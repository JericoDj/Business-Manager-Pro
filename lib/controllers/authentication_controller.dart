import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String email,
    required String homeAddress,
    required String dateOfBirth,
  }) async {
    await _firestore.collection("users").doc(uid).set({
      "uid": uid,
      "name": name,
      "phone": phone,
      "email": email,
      "homeAddress": homeAddress,
      "dateOfBirth": dateOfBirth,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
