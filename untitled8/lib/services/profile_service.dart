import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // Stream of user data
  Stream<UserModel> get userDataStream {
    return _db.collection('users').doc(_uid).snapshots().map((snapshot) {
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    });
  }

  // Update profile data
  Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(_uid).update(user.toMap());
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final ref = _storage.ref().child('user_profiles').child('$_uid.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update the user document with the new image URL
      await _db.collection('users').doc(_uid).update({'profileImageUrl': downloadUrl});
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get user stats (alerts and contacts count)
  Future<Map<String, int>> getUserStats() async {
    final alertsQuery = await _db.collection('alerts').where('userId', isEqualTo: _uid).get();
    final contactsQuery = await _db.collection('contacts').doc(_uid).collection('userContacts').get();
    
    return {
      'alertsCount': alertsQuery.docs.length,
      'contactsCount': contactsQuery.docs.length,
    };
  }
}
