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

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
  Timer? _silenceTimer;
  static const silenceThreshold = Duration(milliseconds: 1000);
  bool _isSpeaking = false;
  final AudioHandlerInterface _audioHandler = createAudioHandler();

  // Remove getter/setter and just make the field public if needed
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
  }

  Future<void> listen({
    required Function(String) onTextRecognized,
    Function()? onSilence,
    Function(String)? onError,
  }) async {
    if (!_isListening) {
      _isListening = true;

      try {
        await _speech.initialize(
          onStatus: (status) {
            print('Speech status: $status'); // Debug print
            if (status == 'notListening') {
              onSilence?.call();
            }
          },
          onError: (error) {
            print('Speech error: $error'); // Debug print
            onError?.call(error.errorMsg);
          },
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
        print('Listen error: $e');
        onError?.call(e.toString());
        _isListening = false;
      }
    }
  }

  Future<void> stop() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      debugPrint('Force stopping all audio...');
      _isSpeaking = false;

      if (kIsWeb) {
        await _audioHandler.stopAllAudio();
      } else {
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
        }
        await _audioPlayer.dispose();
        _audioPlayer = AudioPlayer();
      }
      debugPrint('All audio stopped successfully');
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> forceStopAudio() async {
    try {
      debugPrint('Force stopping ElevenLabs audio...');
      _isSpeaking = false;

      if (kIsWeb) {
        final currentAudio = _audioHandler.audioElement;
        if (currentAudio != null) {
          currentAudio.pause();
          currentAudio.remove();
        }
        await _audioHandler.stopAllAudio();
      } else {
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
          await _audioPlayer.dispose();
          _audioPlayer = AudioPlayer();
        }
      }

      debugPrint('Audio stopped successfully');
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> killAllAudio() async {
    try {
      debugPrint('Killing all audio immediately...');

      if (kIsWeb) {
        await _audioHandler.stopAllAudio();
      } else {
        if (_audioPlayer.playing) {
          _audioPlayer.stop();
        }
        await _audioPlayer.dispose();
        _audioPlayer = AudioPlayer();
      }

      _isSpeaking = false;
      debugPrint('All audio killed successfully');
    } catch (e) {
      debugPrint('Error killing audio: $e');
    }
  }

  Future<bool> speakWithElevenLabs(String text) async {
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
          final file = File('${dir.path}/response_audio.mp3');
          await file.writeAsBytes(response.bodyBytes);

          if (!_isSpeaking) return false;

          try {
            await _audioPlayer.setFilePath(file.path);
            if (!_isSpeaking) return false;
            await _audioPlayer.play();
            await _audioPlayer.playerStateStream.firstWhere(
              (state) =>
                  state.processingState == ProcessingState.completed ||
                  !_isSpeaking,
            );
            return true;
          } finally {
            _isSpeaking = false;
            await file.delete();
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Speech error: $e');
      return false;
    } finally {
      _isSpeaking = false;
    }
  }

  void dispose() async {
    _silenceTimer?.cancel();
    await _audioPlayer.dispose();
    await _speech.stop();
  }
}
