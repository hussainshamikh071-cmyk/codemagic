import 'package:flutter/material.dart';
import '../services/gemini_ai_service.dart';
import 'package:intl/intl.dart';

class AISafetyTipsScreen extends StatefulWidget {
  final String location;

  const AISafetyTipsScreen({Key? key, required this.location}) : super(key: key);

  @override
  _AISafetyTipsScreenState createState() => _AISafetyTipsScreenState();
}

class _AISafetyTipsScreenState extends State<AISafetyTipsScreen> {
  final GeminiAIService _aiService = GeminiAIService();
  String _tips = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    setState(() => _isLoading = true);
    final time = DateFormat('HH:mm').format(DateTime.now());
    final result = await _aiService.getSafetyTips(widget.location, time);
    if (mounted) {
      setState(() {
        _tips = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('AI Safety Guardian'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Safety Tips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Based on your location: ${widget.location}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _tips,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _fetchTips,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Tips'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
