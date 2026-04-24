import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceDetectionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final VoidCallback onEmergencyDetected;

  VoiceDetectionService({required this.onEmergencyDetected});

  final List<String> _keywords = ["HELP", "EMERGENCY", "SOS", "SAVE ME"];

  Future<bool> startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );

    if (available) {
      _isListening = true;
      _speech.listen(
        onResult: (result) {
          String words = result.recognizedWords.toUpperCase();
          print('Heard: $words');
          for (var keyword in _keywords) {
            if (words.contains(keyword)) {
              stopListening();
              onEmergencyDetected();
              break;
            }
          }
        },
        listenFor: const Duration(minutes: 10), // Long duration for monitoring
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );
    }
    return available;
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  bool get isListening => _isListening;
}
