import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PronunciationService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  Timer? _silenceTimer;

  bool get isListening => _isListening;

  Future<void> initialize() async {
    await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
  }

  Future<void> startListening({
    required Function(String) onTextRecognized,
    required Function() onSilence,
    required Duration silenceThreshold,
  }) async {
    if (!_isListening) {
      _isListening = true;

      try {
        await _speech.initialize(
          onStatus: (status) {
            debugPrint('Speech status: $status');
            if (status == 'notListening') {
              onSilence();
            }
          },
          onError: (error) => debugPrint('Speech error: $error'),
        );

        await _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              onTextRecognized(result.recognizedWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
        );
      } catch (e) {
        debugPrint('Listen error: $e');
        _isListening = false;
      }
    }
  }

  Future<void> stop() async {
    if (_isListening) {
      _silenceTimer?.cancel();
      await _speech.stop();
      _isListening = false;
    }
  }

  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
  }
} 