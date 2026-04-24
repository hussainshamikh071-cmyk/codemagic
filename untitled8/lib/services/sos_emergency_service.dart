import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sms_service.dart';
import 'call_service.dart';
import 'notification_service.dart';
import 'location_service.dart';

class SOSEmergencyService {
  final SMSService _smsService = SMSService();
  final CallService _callService = CallService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> triggerSOS() async {
    // 1. Get Current Location
    Position position = await _locationService.getCurrentLocation();
    String address = await _locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    // 2. Get User Data & Contacts
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final String userName = userData['name'] ?? 'User';
    final List<dynamic> contacts = userData['emergency_contacts'] ?? [];

    // 3. Check Connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOffline = connectivityResult == ConnectivityResult.none;

    // 4. Record Alert in Firestore (if online)
    if (!isOffline) {
      await _firestore.collection('sos_alerts').add({
        'userId': user.uid,
        'userName': userName,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    }

    // 5. Send Local Notification
    await _notificationService.showLocalNotification(
      title: "SOS ALERT TRIGGERED",
      body: "Emergency services and contacts are being notified.",
    );

    // 6. Send SMS to all contacts
    if (contacts.isNotEmpty) {
      List<String> phoneNumbers = contacts.map((c) => c['phone'].toString()).toList();
      String message = _smsService.generateLocationMessage(
        userName,
        position.latitude,
        position.longitude,
        address,
      );
      
      await _smsService.sendSOSMessage(
        recipients: phoneNumbers,
        message: message,
      );

      // 7. Auto-call Primary Contact
      await _callService.makeEmergencyCall(phoneNumbers.first);
    }
  }
}
