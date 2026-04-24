import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/gemini_ai_service.dart';
import 'package:intl/intl.dart';

class RiskAnalyzer extends StatefulWidget {
  final String location;
  const RiskAnalyzer({Key? key, required this.location}) : super(key: key);

  @override
  _RiskAnalyzerState createState() => _RiskAnalyzerState();
}

class _RiskAnalyzerState extends State<RiskAnalyzer> {
  final GeminiAIService _aiService = GeminiAIService();
  String _analysis = "Analyzing surroundings...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    final time = DateFormat('HH:mm').format(DateTime.now());
    final result = await _aiService.analyzeRisk(widget.location, time);
    if (mounted) {
      setState(() {
        _analysis = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Risk Assessment',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _analysis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
