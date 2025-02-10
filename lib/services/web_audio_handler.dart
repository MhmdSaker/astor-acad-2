import 'audio_handler_interface.dart';
import 'mock_audio_handler.dart';

class WebAudioHandler implements AudioHandlerInterface {
  final MockAudioHandler _mockHandler = MockAudioHandler();

  @override
  dynamic get audioElement => _mockHandler.audioElement;

  @override
  Future<void> stopAllAudio() async {
    await _mockHandler.stopAllAudio();
  }

  @override
  Future<void> playAudio(List<int> audioBytes) async {
    await _mockHandler.playAudio(audioBytes);
  }
}
