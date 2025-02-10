import 'package:flutter/foundation.dart' show kIsWeb;

abstract class PlatformAudioHandler {
  Future<void> handleAudio(List<int> audioBytes);
  Future<void> stopAudio();
}

class MobileAudioHandler implements PlatformAudioHandler {
  @override
  Future<void> handleAudio(List<int> audioBytes) async {
    // Mobile implementation will be handled in SpeechService
    return;
  }

  @override
  Future<void> stopAudio() async {
    // Mobile implementation will be handled in SpeechService
    return;
  }
}
