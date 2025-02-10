abstract class AudioHandlerInterface {
  dynamic get audioElement;
  Future<void> stopAllAudio();
  Future<void> playAudio(List<int> audioBytes);
} 