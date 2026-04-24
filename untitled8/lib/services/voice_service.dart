import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'unified_sos_service.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final UnifiedSOSService _sosService = UnifiedSOSService();
  
  bool _isListening = false;
  final List<String> _triggerKeywords = ["HELP", "SOS", "EMERGENCY", "SAVE ME"];

  Future<bool> startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    
    if (available) {
      _isListening = true;
      _speech.listen(
        onResult: (val) {
          String heard = val.recognizedWords.toUpperCase();
          for (var keyword in _triggerKeywords) {
            if (heard.contains(keyword)) {
              _triggerVoiceSOS();
              break;
            }
          }
        },
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 10),
        partialResults: true,
      );
    }
    return available;
  }

  void _triggerVoiceSOS() {
    stopListening();
    _sosService.triggerSOS(triggerType: 'voice');
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  bool get isListening => _isListening;
}
