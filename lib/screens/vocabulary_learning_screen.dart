import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VocabularyLearningScreen extends StatefulWidget {
  const VocabularyLearningScreen({super.key});

  @override
  State<VocabularyLearningScreen> createState() => _VocabularyLearningScreenState();
}

class _VocabularyLearningScreenState extends State<VocabularyLearningScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int currentWordIndex = 0;
  int score = 0;
  bool hasAnswered = false;

  // Sample vocabulary data - you can expand this
  final List<Map<String, dynamic>> vocabularyList = [
    {
      'word': 'Apple',
      'audioUrl': 'assets/audio/apple.mp3',
      'correctTranslation': 'تفاحة',
      'correctImage': 'assets/vocab_images/apple.jpg',
      'wrongTranslation': 'موز',
      'wrongImage': 'assets/vocab_images/banana.jpg',
    },
    {
      'word': 'House',
      'audioUrl': 'assets/audio/house.mp3',
      'correctTranslation': 'منزل',
      'correctImage': 'assets/vocab_images/house.jpg',
      'wrongTranslation': 'سيارة',
      'wrongImage': 'assets/vocab_images/car.jpg',
    },
    // Add more vocabulary items
  ];

  // Colors matching the app theme
  static const Color primaryColor = Color(0xFFFF5A1A);
  static const Color backgroundColor = Color(0xFFF7F0EB);
  static const Color textColor = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    _playCurrentWordAudio();
  }

  void _playCurrentWordAudio() async {
    await _audioPlayer.play(AssetSource(vocabularyList[currentWordIndex]['audioUrl']));
  }

  void _checkAnswer(bool isCorrect) {
    if (hasAnswered) return;

    setState(() {
      hasAnswered = true;
      if (isCorrect) score++;
    });

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? const Color(0xFF4CAF50) : Colors.red,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect ? 'Correct!' : 'Wrong!',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The correct translation for "${vocabularyList[currentWordIndex]['word']}" is:',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              vocabularyList[currentWordIndex]['correctTranslation'],
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextWord();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Next Word'),
          ),
        ],
      ),
    );
  }

  void _nextWord() {
    if (currentWordIndex < vocabularyList.length - 1) {
      setState(() {
        currentWordIndex++;
        hasAnswered = false;
      });
      _playCurrentWordAudio();
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              score > vocabularyList.length / 2 ? Icons.emoji_events : Icons.stars,
              color: primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Practice Complete!',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score:',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score/${vocabularyList.length}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Exit',
              style: TextStyle(color: primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                currentWordIndex = 0;
                score = 0;
                hasAnswered = false;
              });
              _playCurrentWordAudio();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = vocabularyList[currentWordIndex];
    final choices = [
      {
        'translation': currentWord['correctTranslation'],
        'image': currentWord['correctImage'],
        'isCorrect': true,
      },
      {
        'translation': currentWord['wrongTranslation'],
        'image': currentWord['wrongImage'],
        'isCorrect': false,
      },
    ]..shuffle(); // Randomize choices order

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          'Vocabulary Learning',
          style: TextStyle(
            fontFamily: 'CraftworkGrotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Score: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Word Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      currentWord['word'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: primaryColor, size: 32),
                      onPressed: _playCurrentWordAudio,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Choose the correct translation:',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Choices
              ...choices.map((choice) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _checkAnswer(choice['isCorrect'] as bool),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Image.asset(
                            choice['image'] as String,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            choice['translation'] as String,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
} 