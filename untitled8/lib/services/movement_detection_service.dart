import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

class MovementDetectionService {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final VoidCallback onFallDetected;
  
  // Thresholds for fall detection
  final double fallThreshold = 25.0; // High acceleration spike
  bool _isMonitoring = false;

  MovementDetectionService({required this.onFallDetected});

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _subscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Calculate total acceleration magnitude
      double magnitude = event.x.abs() + event.y.abs() + event.z.abs();
      
      if (magnitude > fallThreshold) {
        print("Potential fall detected! Magnitude: $magnitude");
        _verifyFall();
      }
    });
  }

  void _verifyFall() {
    // Wait for 3 seconds to see if movement stops (unconsciousness)
    Timer(Duration(seconds: 3), () {
      // In a real app, we'd check if the magnitude remains very low (< 1.0)
      // For this step-by-step, we'll trigger the callback
      onFallDetected();
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _isMonitoring = false;
  }

  bool get isMonitoring => _isMonitoring;
}
