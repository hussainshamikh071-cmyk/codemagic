import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String profileImageUrl;
  final String emergencyNote;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    this.profileImageUrl = '',
    this.emergencyNote = '',
    this.createdAt,
    this.lastLogin,
  });

  // Factory constructor expecting two positional arguments: the data map and the document ID
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id, // Mapping the Firestore Document ID to our uid field
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      emergencyNote: map['emergencyNote'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'emergencyNote': emergencyNote,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastLogin': lastLogin ?? FieldValue.serverTimestamp(),
    };
  }
}