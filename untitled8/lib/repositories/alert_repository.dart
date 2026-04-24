import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AlertRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final String userId;

  AlertRepository({required this.userId});

  String get _path => 'alerts';

  // Get alerts for the current user with pagination
  Future<List<Map<String, dynamic>>> getAlerts({int limit = 10, DocumentSnapshot? startAfter}) async {
    Query query = FirebaseFirestore.instance
        .collection(_path)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
      'docSnapshot': doc, // Useful for pagination
    }).toList();
  }

  // Stream for real-time updates on a specific alert
  Stream<Map<String, dynamic>> streamAlert(String alertId) {
    return FirebaseFirestore.instance
        .collection(_path)
        .doc(alertId)
        .snapshots()
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  Future<void> resolveAlert(String alertId) {
    return _firestoreService.updateData(
      path: '$_path/$alertId',
      data: {'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp()},
    );
  }
}
