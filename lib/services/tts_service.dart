import 'package:flutter_tts/flutter_tts.dart';

/// Service for Text-to-Speech (TTS) functionality.
/// Optimized for elderly users with slower speech rates and bilingual support.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Slower speech rate for better clarity (standard is 0.5)
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  /// Speak the provided [text] in the accent corresponding to [languageCode].
  Future<void> speak(String text, String languageCode) async {
    // Map internal language codes to TTS locales
    final String ttsLanguage = languageCode == 'id' ? 'id-ID' : 'en-US';

    await _flutterTts.setLanguage(ttsLanguage);
    await _flutterTts.speak(text);
  }

  /// Stop current speech immediately.
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Dispose TTS resources (optional, usually handled by OS but good practice).
  void dispose() {
    _flutterTts.stop();
  }
}
