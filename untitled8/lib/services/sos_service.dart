import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class SOSService {
  static const String _primaryKey = 'emergency_primary';
  static const String _secondaryKey1 = 'emergency_secondary1';
  static const String _secondaryKey2 = 'emergency_secondary2';

  // Default emergency numbers (Pakistan: 15, 1122, 130)
  static const String _defaultPrimary = '15';
  static const String _defaultSecondary1 = '1122';
  static const String _defaultSecondary2 = '130';

  // Cache for emergency contacts to avoid repeated SharedPreferences calls
  static EmergencyContacts? _cachedContacts;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // OPTIMIZED: Get stored emergency contacts with caching
  static Future<EmergencyContacts> getContacts() async {
    // Return cached contacts if still valid
    if (_cachedContacts != null && _cacheTimestamp != null) {
      if (DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedContacts!;
      }
    }

    // Load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final contacts = EmergencyContacts(
      primary: prefs.getString(_primaryKey) ?? _defaultPrimary,
      secondary1: prefs.getString(_secondaryKey1) ?? _defaultSecondary1,
      secondary2: prefs.getString(_secondaryKey2) ?? _defaultSecondary2,
    );

    // Update cache
    _cachedContacts = contacts;
    _cacheTimestamp = DateTime.now();

    return contacts;
  }

  // OPTIMIZED: Get contacts synchronously if cached (for immediate UI)
  static EmergencyContacts? getCachedContacts() {
    if (_cachedContacts != null && _cacheTimestamp != null) {
      if (DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        return _cachedContacts;
      }
    }
    return null;
  }

  // Save emergency contacts with cache update
  static Future<void> saveContacts(EmergencyContacts contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryKey, contacts.primary);
    await prefs.setString(_secondaryKey1, contacts.secondary1);
    await prefs.setString(_secondaryKey2, contacts.secondary2);

    // Update cache immediately
    _cachedContacts = contacts;
    _cacheTimestamp = DateTime.now();
  }

  // Clear cache (useful for testing or force refresh)
  static void clearCache() {
    _cachedContacts = null;
    _cacheTimestamp = null;
  }

  // Request SMS and Phone permissions
  static Future<bool> requestPermissions() async {
    final smsStatus = await Permission.sms.request();
    final phoneStatus = await Permission.phone.request();
    return smsStatus.isGranted && phoneStatus.isGranted;
  }

  // Send SOS with location and log to Firestore
  Future<SOSResult> sendSOS({
    required double latitude,
    required double longitude,
    required String address,
    required EmergencyContacts contacts,
  }) async {
    final result = SOSResult();
    final user = _auth.currentUser;

    final googleMapsLink = 'https://www.google.com/maps?q=$latitude,$longitude';
    final currentTime = DateTime.now().toString();

    final message = '''
🆘 SAFETY GUARDIAN SOS 🆘

I need immediate assistance at:
📍 Location: $address
🗺️ Maps Link: $googleMapsLink
📱 Time: $currentTime

This is an automated emergency alert from Safety Guardian app.
    ''';

    // 1. Log to Firestore (don't wait for this to complete)
    if (user != null) {
      _firestore.collection('alerts').add({
        'userId': user.uid,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'googleMapsLink': googleMapsLink,
        'triggeredBy': 'Manual Button',
      }).then((_) {
        result.alertLogged = true;
      }).catchError((e) {
        print('Firestore log failed: $e');
        result.alertLogged = false;
      });
    }

    // 2. Send SMS to each number individually
    List<String> successfullySent = [];
    List<String> failedSends = [];

    // List of all contacts to send SMS to
    final allContacts = [
      contacts.primary,
      contacts.secondary1,
      contacts.secondary2,
    ].where((n) => n.isNotEmpty && n != 'N/A').toList();

    // Send SMS to each contact (in parallel for speed)
    final futures = allContacts.map((number) async {
      try {
        await _sendSMSWithIntent(number, message);
        successfullySent.add(number);
      } catch (e) {
        print('Failed to send SMS to $number: $e');
        failedSends.add(number);
      }
    });

    await Future.wait(futures);

    result.smsSent = successfullySent;
    result.smsFailed = failedSends;

    // 3. Auto-dial primary number
    try {
      await _callNumber(contacts.primary);
      result.callStarted = true;
    } catch (e) {
      print('Failed to start call: $e');
      result.callStarted = false;
    }

    return result;
  }

  // Pre-fill SMS (opens SMS app with message ready)
  Future<void> _sendSMSWithIntent(String phoneNumber, String message) async {
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SENDTO',
        data: 'smsto:$phoneNumber',
        arguments: {'sms_body': message},
      );
      await intent.launch();
    } else {
      final Uri smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw Exception('Could not launch SMS app');
      }
    }
  }

  // Auto-dial
  Future<void> _callNumber(String phoneNumber) async {
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      throw Exception('Could not launch dialer');
    }
  }

  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        List<String> parts = [];

        if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
        if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      print(e);
    }
    return "Lat: $lat, Lng: $lng";
  }
}

class EmergencyContacts {
  final String primary;
  final String secondary1;
  final String secondary2;

  EmergencyContacts({
    required this.primary,
    required this.secondary1,
    required this.secondary2,
  });

  // Helper to get all non-empty contacts
  List<String> get allContacts {
    return [
      primary,
      secondary1,
      secondary2,
    ].where((n) => n.isNotEmpty && n != 'N/A').toList();
  }

  // Helper to check if any contact exists
  bool get hasContacts => allContacts.isNotEmpty;
}

class SOSResult {
  List<String> smsSent = [];
  List<String> smsFailed = [];
  bool callStarted = false;
  bool alertLogged = false;

  bool get hasSmsSent => smsSent.isNotEmpty;
  bool get hasSmsFailed => smsFailed.isNotEmpty;
  bool get isComplete => hasSmsSent || callStarted;

  String get smsSuccessMessage {
    if (smsSent.isEmpty) return 'No SMS sent';
    if (smsSent.length == 1) return 'SMS sent to 1 number';
    return 'SMS sent to ${smsSent.length} numbers';
  }

  String get smsDetails {
    if (smsSent.isEmpty) return '⚠️ Could not send SMS';
    return '✅ Sent to: ${smsSent.join(", ")}';
  }

  String get smsErrorDetails {
    if (smsFailed.isEmpty) return '';
    return 'Failed: ${smsFailed.join(", ")}';
  }
}