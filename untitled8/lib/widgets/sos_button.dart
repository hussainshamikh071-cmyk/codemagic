import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onSOSPressed;
  final bool isLoading;

  const SOSButton({
    super.key,
    required this.onSOSPressed,
    this.isLoading = false,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Shake detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  static const double _shakeThreshold = 30.0;
  static const Duration _shakeCooldown = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startShakeDetection();
  }

  void _startShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final now = DateTime.now();
      if (_lastShakeTime != null &&
          now.difference(_lastShakeTime!) < _shakeCooldown) {
        return;
      }

      // Calculate magnitude (vector length)
      final double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (acceleration > _shakeThreshold) {
        _lastShakeTime = now;
        widget.onSOSPressed();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: FloatingActionButton.large(
        onPressed: widget.isLoading ? null : widget.onSOSPressed,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        heroTag: 'sos_fab',
        child: widget.isLoading
            ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sos, size: 30),
                  SizedBox(height: 4),
                  Text(
                    'SOS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
