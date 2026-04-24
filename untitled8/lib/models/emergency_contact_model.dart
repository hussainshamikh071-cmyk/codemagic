import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;
  final DateTime createdAt;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    required this.isPrimary,
    required this.createdAt,
  });

  factory EmergencyContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmergencyContactModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relation: data['relation'] ?? 'Other',
      isPrimary: data['isPrimary'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
      'isPrimary': isPrimary,
      'createdAt': createdAt,
    };
  }
}
