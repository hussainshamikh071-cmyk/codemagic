import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'sms_service.dart';
import 'call_service.dart';
import 'notification_service.dart';
import 'location_tracking_service.dart';

class UnifiedSOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();
  final SMSService _smsService = SMSService();
  final CallService _callService = CallService();
  final NotificationService _notificationService = NotificationService();
  final LocationTrackingService _trackingService = LocationTrackingService();

  bool _isProcessing = false;

  Future<void> triggerSOS({required String triggerType}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // 1. Get Location
      Position position = await _locationService.getCurrentLocation();
      String address = await _locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
      String mapsLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      // 2. Start Real-time Tracking
      _trackingService.startTracking();
      String trackingLink = _trackingService.getShareableLink();

      // 3. Save Alert to Firestore
      await _firestore.collection('alerts').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'googleMapsLink': mapsLink,
        'trackingLink': trackingLink,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'triggeredBy': triggerType,
      });

      // 4. Show Local Notification
      await _notificationService.showLocalNotification(
        title: "🚨 SOS TRIGGERED ($triggerType)",
        body: "Help is on the way! Emergency contacts notified.",
      );

      // 5. Get Contacts from the new user_contacts subcollection
      final contactsSnapshot = await _firestore
          .collection('contacts')
          .doc(user.uid)
          .collection('user_contacts')
          .get();

      if (contactsSnapshot.docs.isNotEmpty) {
        List<String> phoneNumbers = [];
        String? primaryPhone;

        for (var doc in contactsSnapshot.docs) {
          String phone = doc.data()['phoneNumber'];
          phoneNumbers.add(phone);
          if (doc.data()['isPrimary'] == true) {
            primaryPhone = phone;
          }
        }

        // Fallback: If no primary set, use first contact
        primaryPhone ??= phoneNumbers.first;

        // 6. Send SMS with both location and live tracking link
        String smsMessage = "🚨 SOS ALERT 🚨\nI need help! Triggered via $triggerType.\nLast Location: $mapsLink\nLive Tracking: $trackingLink\nAddress: $address";
        await _smsService.sendSOSMessage(recipients: phoneNumbers, message: smsMessage);

        // 7. Auto Call the primary contact
        await _callService.makeEmergencyCall(primaryPhone);
      }

      // Reset processing flag after cooldown (30s)
      Future.delayed(const Duration(seconds: 30), () {
        _isProcessing = false;
      });

    } catch (e) {
      _isProcessing = false;
      rethrow;
    }
  }

  void resolveEmergency() {
    _trackingService.stopTracking();
  }
}
