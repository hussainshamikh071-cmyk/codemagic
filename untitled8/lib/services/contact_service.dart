import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  CollectionReference get _contactsRef =>
      _firestore.collection('contacts').doc(_uid).collection('user_contacts');

  /// 1 & 2 & 3 & 4. Intelligent Contact Analysis
  /// Returns a JSON-style Map for UI processing
  Future<Map<String, dynamic>> analyzeContactInput(String name, String phone) async {
    String relation = "Other";
    String warning = "";
    bool isValid = true;
    bool suggestPrimary = false;

    // 1. Suggest Relation based on common Pakistani/English names
    final nameLower = name.toLowerCase();
    if (RegExp(r'ammi|abba|abbu|maa|mother|father|mom|dad|papa').hasMatch(nameLower)) {
      relation = "Parent";
      suggestPrimary = true;
    } else if (RegExp(r'bhai|behan|brother|sister|api').hasMatch(nameLower)) {
      relation = "Sibling";
    } else if (RegExp(r'wife|husband|spouse|shohar').hasMatch(nameLower)) {
      relation = "Spouse";
      suggestPrimary = true;
    }

    // 2. Validate Phone Number (11 digits for Pakistan)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length != 11) {
      isValid = false;
      warning = "Invalid number. Please enter a 11-digit mobile number (e.g. 03001234567).";
    }

    // 3. Detect Duplicate Contacts
    final duplicateCheck = await _contactsRef.where('phone', isEqualTo: phone).get();
    if (duplicateCheck.docs.isNotEmpty) {
      warning = "This contact already exists in your emergency list.";
      isValid = false;
    }

    return {
      "name": name,
      "phone": phone,
      "relation": relation,
      "isValid": isValid,
      "warning": warning,
      "suggestPrimary": suggestPrimary
    };
  }

  /// 5. Emergency Optimization (Safety Audit)
  Future<Map<String, dynamic>> getSafetyAudit() async {
    final snapshot = await _contactsRef.get();
    final contacts = snapshot.docs;

    bool hasPrimary = contacts.any((doc) => (doc.data() as Map)['isPrimary'] == true);
    int count = contacts.length;

    String recommendation = "";
    if (count < 2) {
      recommendation = "Add at least 2 contacts for better safety coverage.";
    } else if (!hasPrimary) {
      recommendation = "You haven't set a Primary Contact. We recommend marking a Parent or Spouse.";
    }

    return {
      "isReady": count >= 2 && hasPrimary,
      "contactCount": count,
      "hasPrimary": hasPrimary,
      "recommendation": recommendation,
    };
  }

  /// 6. SOS Message Generation
  /// Generates a short, urgent message for emergency contacts
  String generateSOSMessage({double? latitude, double? longitude}) {
    String message = "🚨 SOS EMERGENCY! I am in danger and need help immediately.";
    
    if (latitude != null && longitude != null) {
      message += " My live location: https://maps.google.com/?q=$latitude,$longitude";
    }
    
    message += " Please call my primary contact and reach me ASAP.";
    
    // Ensure message stays within 200 characters if possible, though emergency context takes priority
    return message;
  }

  Stream<List<EmergencyContactModel>> getContactsStream() {
    return _contactsRef.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyContactModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addContact({
    required String name,
    required String phone,
    required String relation,
    required bool isPrimary,
  }) async {
    if (isPrimary) {
      await _unsetExistingPrimary();
    }
    await _contactsRef.add({
      'name': name,
      'phone': phone,
      'relation': relation,
      'isPrimary': isPrimary,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateContact({
    required String contactId,
    required String name,
    required String phone,
    required String relation,
    required bool isPrimary,
  }) async {
    if (isPrimary) {
      await _unsetExistingPrimary();
    }
    await _contactsRef.doc(contactId).update({
      'name': name,
      'phone': phone,
      'relation': relation,
      'isPrimary': isPrimary,
    });
  }

  Future<void> deleteContact(String contactId) async {
    await _contactsRef.doc(contactId).delete();
  }

  Future<void> _unsetExistingPrimary() async {
    final query = await _contactsRef.where('isPrimary', isEqualTo: true).get();
    for (var doc in query.docs) {
      await doc.reference.update({'isPrimary': false});
    }
  }
}
