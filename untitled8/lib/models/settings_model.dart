class SettingsModel {
  final bool autoSOSEnabled;
  final bool voiceDetectionEnabled;
  final bool fallDetectionEnabled;
  final bool liveTrackingEnabled;
  final bool backgroundLocationEnabled;
  final int locationInterval;
  final bool pushNotificationsEnabled;
  final bool smsAlertsEnabled;
  final bool soundAlarmEnabled;
  final bool hideLocationFromContacts;
  final bool dataEncryptionEnabled;

  SettingsModel({
    this.autoSOSEnabled = false,
    this.voiceDetectionEnabled = false,
    this.fallDetectionEnabled = false,
    this.liveTrackingEnabled = true,
    this.backgroundLocationEnabled = true,
    this.locationInterval = 10,
    this.pushNotificationsEnabled = true,
    this.smsAlertsEnabled = true,
    this.soundAlarmEnabled = true,
    this.hideLocationFromContacts = false,
    this.dataEncryptionEnabled = true,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      autoSOSEnabled: map['autoSOSEnabled'] ?? false,
      voiceDetectionEnabled: map['voiceDetectionEnabled'] ?? false,
      fallDetectionEnabled: map['fallDetectionEnabled'] ?? false,
      liveTrackingEnabled: map['liveTrackingEnabled'] ?? true,
      backgroundLocationEnabled: map['backgroundLocationEnabled'] ?? true,
      locationInterval: map['locationInterval'] ?? 10,
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      smsAlertsEnabled: map['smsAlertsEnabled'] ?? true,
      soundAlarmEnabled: map['soundAlarmEnabled'] ?? true,
      hideLocationFromContacts: map['hideLocationFromContacts'] ?? false,
      dataEncryptionEnabled: map['dataEncryptionEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoSOSEnabled': autoSOSEnabled,
      'voiceDetectionEnabled': voiceDetectionEnabled,
      'fallDetectionEnabled': fallDetectionEnabled,
      'liveTrackingEnabled': liveTrackingEnabled,
      'backgroundLocationEnabled': backgroundLocationEnabled,
      'locationInterval': locationInterval,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'smsAlertsEnabled': smsAlertsEnabled,
      'soundAlarmEnabled': soundAlarmEnabled,
      'hideLocationFromContacts': hideLocationFromContacts,
      'dataEncryptionEnabled': dataEncryptionEnabled,
    };
  }

  SettingsModel copyWith({
    bool? autoSOSEnabled,
    bool? voiceDetectionEnabled,
    bool? fallDetectionEnabled,
    bool? liveTrackingEnabled,
    bool? backgroundLocationEnabled,
    int? locationInterval,
    bool? pushNotificationsEnabled,
    bool? smsAlertsEnabled,
    bool? soundAlarmEnabled,
    bool? hideLocationFromContacts,
    bool? dataEncryptionEnabled,
  }) {
    return SettingsModel(
      autoSOSEnabled: autoSOSEnabled ?? this.autoSOSEnabled,
      voiceDetectionEnabled: voiceDetectionEnabled ?? this.voiceDetectionEnabled,
      fallDetectionEnabled: fallDetectionEnabled ?? this.fallDetectionEnabled,
      liveTrackingEnabled: liveTrackingEnabled ?? this.liveTrackingEnabled,
      backgroundLocationEnabled: backgroundLocationEnabled ?? this.backgroundLocationEnabled,
      locationInterval: locationInterval ?? this.locationInterval,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      smsAlertsEnabled: smsAlertsEnabled ?? this.smsAlertsEnabled,
      soundAlarmEnabled: soundAlarmEnabled ?? this.soundAlarmEnabled,
      hideLocationFromContacts: hideLocationFromContacts ?? this.hideLocationFromContacts,
      dataEncryptionEnabled: dataEncryptionEnabled ?? this.dataEncryptionEnabled,
    );
  }
}
