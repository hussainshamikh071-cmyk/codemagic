import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiAIService {
  late final GenerativeModel _model;
  
  GeminiAIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<Map<String, dynamic>> processContactInput(String name, String phone) async {
    try {
      final prompt = """
        You are an emergency contact assistant. Analyze this contact:
        Name: "$name"
        Phone: "$phone"

        Rules:
        1. Suggest relation: "Parent" if name is like Ammi/Abbu/Mom/Dad, "Sibling" if Brother/Sister/Bhai, "Spouse" if Wife/Husband. Default "Friend".
        2. Validate phone: Must be 11 digits for Pakistan.
        3. Suggest primary: true if relation is Parent or Spouse.
        4. Emergency optimization: If this is the only contact provided, warn about needing at least 2.

        Output ONLY JSON:
        {
          "name": "...",
          "phone": "...",
          "relation": "...",
          "isValid": true/false,
          "warning": "...",
          "suggestPrimary": true/false
        }
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final jsonResponse = jsonDecode(response.text ?? '{}');
      return jsonResponse;
    } catch (e) {
      return {
        "name": name,
        "phone": phone,
        "relation": "Friend",
        "isValid": false,
        "warning": "Error processing input: $e",
        "suggestPrimary": false
      };
    }
  }

  Future<String> generateSOSMessage({String? locationLink}) async {
    try {
      final prompt = """
        You are an emergency response AI. Generate a short SOS message.
        User is in danger. 
        Current location: ${locationLink ?? "[Location not available]"}
        Request for immediate help.

        Rules:
        - Keep message under 200 characters.
        - Make it urgent and clear.
        - Output the message directly.
      """;
      
      // Temporary model instance without JSON constraint for plain text message
      final textModel = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );
      
      final content = [Content.text(prompt)];
      final response = await textModel.generateContent(content);
      return response.text ?? "🚨 SOS EMERGENCY! I am in danger and need help NOW. My live location: ${locationLink ?? "[Not available]"}. Please respond immediately.";
    } catch (e) {
      return "🚨 SOS EMERGENCY! I am in danger and need help NOW. My live location: ${locationLink ?? "[Not available]"}. Please respond immediately.";
    }
  }

  Future<String> getSafetyTips(String location, String time) async {
    try {
      final prompt = "I am at $location and the current time is $time. "
          "Provide 3 concise, practical personal safety tips for this context. "
          "Format as a list.";
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Stay alert and keep your phone charged.";
    } catch (e) {
      return "Error: Unable to fetch safety tips. Please stay aware of your surroundings.";
    }
  }

  Future<String> analyzeRisk(String location, String time) async {
    try {
      final prompt = "Analyze the personal safety risk for a person at $location during $time. "
          "Provide a risk level (Low, Medium, High) and a short justification. "
          "Keep it under 50 words.";
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Risk analysis unavailable.";
    } catch (e) {
      return "Risk Level: Unknown. Reason: Service connectivity issue.";
    }
  }

  Future<bool> detectEmergency(String input) async {
    try {
      final prompt = "Does this input indicate an immediate personal safety emergency? "
          "Input: '$input'. Respond with only 'YES' or 'NO'.";
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim().toUpperCase() == "YES";
    } catch (e) {
      return false;
    }
  }
}
