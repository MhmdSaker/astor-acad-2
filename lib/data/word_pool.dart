class WordPool {
  static const List<Map<String, String>> words = [
    {'word': 'HOUSE', 'hint': 'A place where people live'},
    {'word': 'APPLE', 'hint': 'A common fruit'},
    {'word': 'BEACH', 'hint': 'Sandy shore by the ocean'},
    {'word': 'CHAIR', 'hint': 'Furniture to sit on'},
    {'word': 'PHONE', 'hint': 'Device for communication'},
    {'word': 'WATER', 'hint': 'Clear liquid to drink'},
    {'word': 'BREAD', 'hint': 'Baked food made from flour'},
    {'word': 'CLOCK', 'hint': 'Shows the time'},
    {'word': 'TABLE', 'hint': 'Flat surface for eating or working'},
    {'word': 'LIGHT', 'hint': 'Makes things visible'},
    {'word': 'MUSIC', 'hint': 'Pleasant sounds to hear'},
    {'word': 'PAPER', 'hint': 'Material for writing'},
    {'word': 'SHOES', 'hint': 'Footwear for protection'},
    {'word': 'PLANT', 'hint': 'Living thing that grows'},
    {'word': 'SMILE', 'hint': 'Happy expression'},
    {'word': 'CLOUD', 'hint': 'White formation in sky'},
    {'word': 'RIVER', 'hint': 'Flowing body of water'},
    {'word': 'SLEEP', 'hint': 'Rest at night'},
    {'word': 'DREAM', 'hint': 'Images in sleep'},
    {'word': 'HEART', 'hint': 'Organ that pumps blood'},
  ];

  static List<Map<String, String>> getRandomWords(int count) {
    final List<Map<String, String>> wordsCopy = List.from(words);
    wordsCopy.shuffle();
    return wordsCopy
        .take(count)
        .map((map) => {
              'word': map['word']!,
              'hint': map['hint']!,
            })
        .toList();
  }
}
