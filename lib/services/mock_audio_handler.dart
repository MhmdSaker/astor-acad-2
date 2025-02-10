import 'audio_handler_interface.dart';

class MockAudioHandler implements AudioHandlerInterface {
  @override
  dynamic get audioElement => null;

  @override
  Future<void> stopAllAudio() async {}

  @override
  Future<void> playAudio(List<int> audioBytes) async {}
} 