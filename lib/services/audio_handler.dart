import 'package:flutter/foundation.dart' show kIsWeb;
import 'audio_handler_interface.dart';
import 'mock_audio_handler.dart';
import 'web_audio_handler.dart' if (dart.library.html) 'web/audio_handler_web.dart';

// Create a typedef for the handler constructor
typedef AudioHandlerConstructor = AudioHandlerInterface Function();

// Import the web version only when running on web
@pragma('vm:entry-point')
AudioHandlerConstructor createPlatformHandler() {
  if (!kIsWeb) {
    return () => MockAudioHandler();
  }
  // Web implementation will override this
  return () => throw UnsupportedError(
      'Cannot create web audio handler in non-web platform');
}

// The actual factory function
AudioHandlerInterface createAudioHandler() {
  if (kIsWeb) {
    return WebAudioHandler();
  }
  return MockAudioHandler();
} 