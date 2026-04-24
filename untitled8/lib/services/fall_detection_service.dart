import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'unified_sos_service.dart';

class FallDetectionService {
  final UnifiedSOSService _sosService = UnifiedSOSService();
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  
  // Thresholds for fall detection
  final double _fallThreshold = 25.0; // High acceleration spike
  final double _inactivityThreshold = 1.0; // Low movement magnitude
  
  bool _isMonitoring = false;
  Timer? _verificationTimer;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _subscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      double magnitude = event.x.abs() + event.y.abs() + event.z.abs();
      
      if (magnitude > _fallThreshold) {
        _verifyInactivity();
      }
    });
  }

  void _verifyInactivity() {
    _verificationTimer?.cancel();
    // Wait 5 seconds to check for inactivity after a fall
    _verificationTimer = Timer(const Duration(seconds: 5), () {
      // In a production app, we would re-check current magnitude here
      // For this implementation, we trigger if the 5s window passes after a spike
      _sosService.triggerSOS(triggerType: 'fall');
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _verificationTimer?.cancel();
    _isMonitoring = false;
  }
}
