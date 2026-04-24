import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/settings_model.dart';

class SettingsService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  SettingsModel _settings = SettingsModel();
  bool _isLoading = true;

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsService() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToSettings(user.uid);
      } else {
        _settings = SettingsModel();
        notifyListeners();
      }
    });
  }

  void _listenToSettings(String uid) {
    _db.collection('users').doc(uid).collection('settings').doc('app_settings').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _settings = SettingsModel.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        // Create default settings if they don't exist
        _updateSettingsInFirebase(uid, _settings);
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _settings = newSettings;
      notifyListeners();
      await _updateSettingsInFirebase(uid, newSettings);
    }
  }

  Future<void> _updateSettingsInFirebase(String uid, SettingsModel settings) async {
    await _db.collection('users').doc(uid).collection('settings').doc('app_settings').set(
      settings.toMap(),
      SetOptions(merge: true),
    );
  }

  // Toggle helpers for easier UI integration
  Future<void> toggleAutoSOS(bool value) => updateSettings(_settings.copyWith(autoSOSEnabled: value));
  Future<void> toggleVoiceDetection(bool value) => updateSettings(_settings.copyWith(voiceDetectionEnabled: value));
  Future<void> toggleFallDetection(bool value) => updateSettings(_settings.copyWith(fallDetectionEnabled: value));
  Future<void> toggleLiveTracking(bool value) => updateSettings(_settings.copyWith(liveTrackingEnabled: value));
  Future<void> toggleBackgroundLocation(bool value) => updateSettings(_settings.copyWith(backgroundLocationEnabled: value));
  Future<void> setLocationInterval(int value) => updateSettings(_settings.copyWith(locationInterval: value));
  Future<void> toggleNotifications(bool value) => updateSettings(_settings.copyWith(pushNotificationsEnabled: value));
  Future<void> toggleSMSAlerts(bool value) => updateSettings(_settings.copyWith(smsAlertsEnabled: value));
  Future<void> toggleSoundAlarm(bool value) => updateSettings(_settings.copyWith(soundAlarmEnabled: value));
  Future<void> toggleHideLocation(bool value) => updateSettings(_settings.copyWith(hideLocationFromContacts: value));
  Future<void> toggleEncryption(bool value) => updateSettings(_settings.copyWith(dataEncryptionEnabled: value));
}
