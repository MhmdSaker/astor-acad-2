class WebAudioHandler {
  // Add mock webAudio property
  dynamic get webAudio => null;
  set webAudio(dynamic value) {}

  Future<void> stopAllAudio() async {}
  Future<void> playAudio(List<int> audioBytes) async {}
} 