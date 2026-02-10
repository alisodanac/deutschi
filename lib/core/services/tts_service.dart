import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();

    // Configure for German
    await _flutterTts.setLanguage("de-DE");
    await _flutterTts.setSpeechRate(0.5); // Normal speed is 0.5 (1.0 is fast)
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Handle iOS audio session to not mute other apps completely but duck?
    // Or just default.
    await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.allowBluetooth,
      IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      IosTextToSpeechAudioCategoryOptions.mixWithOthers,
    ], IosTextToSpeechAudioMode.defaultMode);

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _flutterTts.stop();
    }
  }
}
