import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  // Cache duration: 1 hour
  static const Duration _cacheDuration = Duration(hours: 1);
  
  Future<SafetyAssessment> analyzeLocation({
    required String locationName,
    required double lat,
    required double lng,
  }) async {
    // Check cache first
    final cached = await _getCachedAssessment(locationName, lat, lng);
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    
    // Build the prompt
    final prompt = _buildSafetyPrompt(locationName, lat, lng);
    
    // Make API call
    final response = await _callOpenRouterAPI(prompt);
    
    // Parse and cache response
    final assessment = SafetyAssessment.fromJson(
      jsonDecode(response),
      locationName,
      lat,
      lng,
    );
    
    await _cacheAssessment(assessment);
    return assessment;
  }
  
  String _buildSafetyPrompt(String locationName, double lat, double lng) {
    return '''
You are a safety risk assessment AI for "Safety Guardian" app - a personal safety companion.

Location: "$locationName" at coordinates ($lat, $lng)

Provide a comprehensive safety analysis. Return ONLY valid JSON in exactly this format, no other text:

{
  "safetyScore": 85,
  "riskLevel": "Low",
  "riskFactors": ["Well-lit area", "Active community", "Emergency services nearby"],
  "daytimeSafety": "Very safe during daylight hours",
  "nighttimeSafety": "Use caution after 11 PM",
  "emergencyAdvice": "Closest hospital: City General (0.5 miles)",
  "safeZones": ["Main shopping district", "Police station area", "Public park"]
}

For the safetyScore: 0-30 (Critical Risk), 31-50 (High Risk), 51-70 (Medium Risk), 71-100 (Low Risk).

Base on general knowledge. If location is completely unknown, default to safetyScore: 65, riskLevel: "Medium".
''';
  }
  
  Future<String> _callOpenRouterAPI(String prompt) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    final appDomain = dotenv.env['APP_DOMAIN'] ?? 'https://safetyguardian.app';
    
    if (apiKey == null) {
      throw Exception('OpenRouter API key not found. Add OPENROUTER_API_KEY to .env');
    }
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': appDomain,
      'X-Title': 'Safety Guardian App',
    };
    
    final body = jsonEncode({
      'model': 'openrouter/free',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a safety assessment AI. Return ONLY valid JSON.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.3,
      'max_tokens': 800,
    });
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 402) {
        throw Exception('⚠️ Payment Required. Make sure you\'re using :free model suffix!');
      } else {
        throw Exception('OpenRouter API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze location: $e');
    }
  }
  
  Future<void> _cacheAssessment(SafetyAssessment assessment) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'risk_${assessment.locationName.toLowerCase()}_${assessment.lat.toStringAsFixed(2)}_${assessment.lng.toStringAsFixed(2)}';
    await prefs.setString(cacheKey, jsonEncode(assessment.toJson()));
    await prefs.setString('${cacheKey}_timestamp', assessment.timestamp.toIso8601String());
  }
  
  Future<SafetyAssessment?> _getCachedAssessment(String name, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'risk_${name.toLowerCase()}_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';
    final cachedJson = prefs.getString(cacheKey);
    
    if (cachedJson != null) {
      final timestampStr = prefs.getString('${cacheKey}_timestamp');
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return SafetyAssessment.fromJson(jsonDecode(cachedJson), name, lat, lng);
        }
      }
    }
    return null;
  }
}

class SafetyAssessment {
  final String locationName;
  final double lat;
  final double lng;
  final int safetyScore;
  final String riskLevel;
  final List<String> riskFactors;
  final String daytimeSafety;
  final String nighttimeSafety;
  final String emergencyAdvice;
  final List<String> safeZones;
  final DateTime timestamp;
  
  SafetyAssessment({
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.safetyScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.daytimeSafety,
    required this.nighttimeSafety,
    required this.emergencyAdvice,
    required this.safeZones,
    required this.timestamp,
  });
  
  factory SafetyAssessment.fromJson(Map<String, dynamic> json, String name, double lat, double lng) {
    return SafetyAssessment(
      locationName: name,
      lat: lat,
      lng: lng,
      safetyScore: json['safetyScore'] ?? 65,
      riskLevel: json['riskLevel'] ?? 'Medium',
      riskFactors: List<String>.from(json['riskFactors'] ?? ['Standard urban area']),
      daytimeSafety: json['daytimeSafety'] ?? 'Exercise normal precautions',
      nighttimeSafety: json['nighttimeSafety'] ?? 'Stay in well-lit areas',
      emergencyAdvice: json['emergencyAdvice'] ?? 'Call local emergency services if needed',
      safeZones: List<String>.from(json['safeZones'] ?? ['Well-populated areas']),
      timestamp: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'safetyScore': safetyScore,
    'riskLevel': riskLevel,
    'riskFactors': riskFactors,
    'daytimeSafety': daytimeSafety,
    'nighttimeSafety': nighttimeSafety,
    'emergencyAdvice': emergencyAdvice,
    'safeZones': safeZones,
  };
  
  bool get isExpired => DateTime.now().difference(timestamp).inHours >= 1;
  
  Color get riskColor {
    switch (riskLevel.toLowerCase()) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'critical': return Colors.deepPurple;
      default: return Colors.grey;
    }
  }
  
  String get safetyMessage {
    if (safetyScore >= 80) return 'Very Safe';
    if (safetyScore >= 60) return 'Moderately Safe';
    if (safetyScore >= 40) return 'Caution Advised';
    return 'High Risk Area';
  }
}
