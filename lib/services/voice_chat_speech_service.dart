import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';
import 'audio_handler.dart';
import 'audio_handler_interface.dart';

// Create a conditional import for web audio handling
import 'web_audio_handler.dart' if (dart.library.io) 'mock_web_audio_handler.dart';

class VoiceChatSpeechService {
  final SpeechToText _speech = SpeechToText();
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
  bool _isSpeaking = false;
  Timer? _silenceTimer;
  final AudioHandlerInterface _audioHandler = createAudioHandler();
  
  // Public getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  // Initialize speech recognition
  Future<bool> initialize() async {
    try {
      final initialized = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      return initialized;
    } catch (e) {
      debugPrint('Initialization error: $e');
      return false;
    }
  }

  // Start listening with continuous recognition
  Future<void> startListening({
    required Function(String) onTextRecognized,
    required Function() onSilence,
    Duration silenceThreshold = const Duration(seconds: 2),
  }) async {
    if (_isListening) return;

    try {
      _isListening = true;
      
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onTextRecognized(result.recognizedWords);
            _resetSilenceTimer(onSilence, silenceThreshold);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        onSoundLevelChange: (level) {
          if (level <= 0) {
            _resetSilenceTimer(onSilence, silenceThreshold);
          }
        },
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      _isListening = false;
      rethrow;
    }
  }

  void _resetSilenceTimer(Function() onSilence, Duration threshold) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(threshold, () {
      if (_isListening) {
        onSilence();
      }
    });
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      _silenceTimer?.cancel();
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      debugPrint('Stop listening error: $e');
      rethrow;
    }
  }

  // Speak text using ElevenLabs
  Future<bool> speak(String text) async {
    if (_isSpeaking) return false;

    try {
      _isSpeaking = true;

      final url = Uri.parse(
          'https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM/stream');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': ApiConfig.elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_multilingual_v1',
          'voice_settings': {
            'stability': 0.7,
            'similarity_boost': 0.8,
          }
        }),
      );

      if (!_isSpeaking) return false;

      if (response.statusCode == 200) {
        if (kIsWeb) {
          await _audioHandler.playAudio(response.bodyBytes);
          return true;
        } else {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/voice_chat_audio.mp3');
          await file.writeAsBytes(response.bodyBytes);

          if (!_isSpeaking) {
            await file.delete();
            return false;
          }

          try {
            await _audioPlayer.setFilePath(file.path);
            if (!_isSpeaking) return false;
            
            await _audioPlayer.play();
            await _audioPlayer.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed || !_isSpeaking,
            );
            return true;
          } finally {
            await file.delete();
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Speak error: $e');
      return false;
    } finally {
      _isSpeaking = false;
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    
    try {
      if (kIsWeb) {
        await _audioHandler.stopAllAudio();
      } else {
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
        }
      }
    } catch (e) {
      debugPrint('Stop speaking error: $e');
    }
  }

  // Cleanup resources
  Future<void> dispose() async {
    _silenceTimer?.cancel();
    await stopListening();
    await stopSpeaking();
    await _audioPlayer.dispose();
  }
} 