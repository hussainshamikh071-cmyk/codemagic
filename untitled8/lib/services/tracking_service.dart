import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to real-time location updates for a specific user
  Stream<DocumentSnapshot<Map<String, dynamic>>> getLiveLocationStream(String userId) {
    return _firestore.collection('live_tracking').doc(userId).snapshots();
  }

  /// Generate a shareable link for tracking (Example format)
  String generateTrackingLink(String userId) {
    // In a real app, this would be your web app domain or deep link
    return "https://safety-guardian.app/track/$userId";
  }
}
