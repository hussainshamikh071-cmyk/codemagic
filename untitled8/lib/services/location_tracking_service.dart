import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  void startTracking() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Set status to active
    _firestore.collection('live_tracking').doc(user.uid).set({
      'isActive': true,
      'userName': user.displayName ?? 'User',
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Start listening to position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(seconds: 5), // Or every 5 seconds
      ),
    ).listen((Position position) {
      _firestore.collection('live_tracking').doc(user.uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    });
  }

  void stopTracking() {
    final user = _auth.currentUser;
    if (user == null) return;

    _positionStreamSubscription?.cancel();
    _firestore.collection('live_tracking').doc(user.uid).update({
      'isActive': false,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  String getShareableLink() {
    final user = _auth.currentUser;
    if (user == null) return "";
    // In a real app, use your custom domain or Firebase Dynamic Links
    return "https://safety-guardian.app/track/${user.uid}";
  }
}
