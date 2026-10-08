import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  final FlutterTts _flutterTts = FlutterTts();

  factory TtsService() => _instance;

  TtsService._internal() {
    _configure();
  }

  Future<void> _configure() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
