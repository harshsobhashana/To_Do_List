// services/speech_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText speechToText;
  final FlutterTts tts;
  bool _isListening = false;
  
  SpeechService({
    required this.speechToText,
    required this.tts,
  }) {
    _initializeTts();
  }
  
  Future<void> _initializeTts() async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
  }
  
  bool get isListening => _isListening;
  
  Future<bool> startListening(Function(SpeechRecognitionResult) onResult) async {
    if (!_isListening) {
      final available = await speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      
      if (available) {
        _isListening = true;
        await speechToText.listen(
          onResult: onResult,
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          localeId: 'en_US',
        );
        return true;
      }
    }
    return false;
  }
  
  Future<void> stopListening() async {
    await speechToText.stop();
    _isListening = false;
  }
  
  Future<void> speak(String text) async {
    await tts.speak(text);
  }
}
