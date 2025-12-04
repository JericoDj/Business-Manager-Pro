import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String homeAddress;
  final String dateOfBirth;
  final String role;         // admin | super_admin | user
  final String companyId;    // the company this user belongs to
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.homeAddress,
    required this.dateOfBirth,
    required this.role,
    required this.companyId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'homeAddress': homeAddress,
      'dateOfBirth': dateOfBirth,
      'role': role,
      'companyId': companyId,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      homeAddress: map['homeAddress'],
      dateOfBirth: map['dateOfBirth'],
      role: map['role'],
      companyId: map['companyId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
