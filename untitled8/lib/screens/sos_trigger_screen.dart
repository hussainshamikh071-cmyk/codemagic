import 'package:flutter/material.dart';
import '../services/unified_sos_service.dart';
import 'package:provider/provider.dart';

class SOSTriggerScreen extends StatefulWidget {
  const SOSTriggerScreen({Key? key}) : super(key: key);

  @override
  _SOSTriggerScreenState createState() => _SOSTriggerScreenState();
}

class _SOSTriggerScreenState extends State<SOSTriggerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    setState(() => _isProcessing = true);
    try {
      // ✅ Using UnifiedSOSService correctly from Provider
      final sosService = Provider.of<UnifiedSOSService>(context, listen: false);
      await sosService.triggerSOS(triggerType: 'Manual Button');
      _showSuccessDialog();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'Emergency Alert Sent Successfully!\n\nSMS sent to all contacts and call initiated to primary contact.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Safety'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SOS Failed: $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B0000), Color(0xFF0F0F0F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'EMERGENCY MODE',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              const Text(
                'Help is one tap away',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: 250 * _animation.value,
                        height: 250 * _animation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.1),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: _isProcessing ? null : _triggerSOS,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                        gradient: const RadialGradient(
                          colors: [Colors.redAccent, Color(0xFF8B0000)],
                        ),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 6)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 50),
                                  Text(
                                    'SOS',
                                    style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Tapping the button will notify your emergency contacts with your live location and call your primary contact.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
