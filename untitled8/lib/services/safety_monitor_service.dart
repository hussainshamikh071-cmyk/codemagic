import 'package:flutter/foundation.dart';
import 'fall_detection_service.dart';
import 'voice_service.dart';
import 'settings_service.dart';

class SafetyMonitorService extends ChangeNotifier {
  final FallDetectionService _fallService = FallDetectionService();
  final VoiceService _voiceService = VoiceService();
  final SettingsService _settingsService;

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  SafetyMonitorService(this._settingsService) {
    _settingsService.addListener(_onSettingsChanged);
    _initMonitoring();
  }

  void _onSettingsChanged() {
    _initMonitoring();
  }

  void _initMonitoring() {
    final settings = _settingsService.settings;

    // Fall Detection Toggle
    if (settings.fallDetectionEnabled) {
      _fallService.startMonitoring();
    } else {
      _fallService.stopMonitoring();
    }

    // Voice Detection Toggle
    if (settings.voiceDetectionEnabled) {
      if (!_voiceService.isListening) {
        _voiceService.startListening();
      }
    } else {
      _voiceService.stopListening();
    }

    _isMonitoring = settings.fallDetectionEnabled || settings.voiceDetectionEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _fallService.stopMonitoring();
    _voiceService.stopListening();
    super.dispose();
  }
}
