import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import '../audio_handler_interface.dart';
import '../audio_handler.dart';

// Register the web implementation
class WebAudioHandlerPlugin {
  static void registerWith(Registrar registrar) {
    // Registration code if needed
  }
}

@pragma('vm:entry-point')
AudioHandlerConstructor createPlatformHandler() {
  return () => WebAudioHandler();
}

class WebAudioHandler implements AudioHandlerInterface {
  html.AudioElement? _audioElement;

  @override
  html.AudioElement? get audioElement => _audioElement;

  @override
  Future<void> stopAllAudio() async {
    if (_audioElement != null) {
      _audioElement!.pause();
      _audioElement!.remove();
      _audioElement = null;
    }
    
    final elements = html.window.document.getElementsByTagName('audio');
    for (var i = elements.length - 1; i >= 0; i--) {
      final audio = elements[i] as html.AudioElement;
      audio.pause();
      audio.remove();
    }
  }

  @override
  Future<void> playAudio(List<int> audioBytes) async {
    final blob = html.Blob([audioBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    _audioElement = html.AudioElement()
      ..src = url
      ..autoplay = true;

    try {
      await _audioElement?.onEnded.first;
    } finally {
      html.Url.revokeObjectUrl(url);
      _audioElement = null;
    }
  }
} 