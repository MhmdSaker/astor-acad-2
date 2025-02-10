import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import '../../utils/game_animations.dart';
import '../../data/word_pool.dart';
import '../../widgets/game_completion_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/text_styles.dart';
import '../../services/score_service.dart';

class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({super.key});

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame>
    with SingleTickerProviderStateMixin {
  late List<Map<String, String>> _words;
  late String _currentWord;
  late String _scrambledWord;
  late String _hint;
  String _userInput = '';
  bool _isCorrect = false;
  int _score = 0;
  int _currentIndex = 0;
  late TextEditingController _textController;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _words = WordPool.getRandomWords(8); // Get 8 random words
    _textController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = GameAnimations.createShakeAnimation(_animationController);
    _scaleAnimation = GameAnimations.createScaleAnimation(_animationController);
    _bounceAnimation =
        GameAnimations.createBounceAnimation(_animationController);
    _loadNewWord();
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadNewWord() {
    if (_currentIndex >= _words.length) {
      // Game completed
      _showGameComplete();
      return;
    }

    setState(() {
      _currentWord = _words[_currentIndex]['word']!;
      _hint = _words[_currentIndex]['hint']!;
      _scrambledWord = _scrambleWord(_currentWord);
      _userInput = '';
      _isCorrect = false;
    });
  }

  String _scrambleWord(String word) {
    List<String> letters = word.split('');
    Random random = Random();

    // Keep shuffling until we get a different arrangement
    String scrambled;
    do {
      letters.shuffle(random);
      scrambled = letters.join();
    } while (scrambled == word);

    return scrambled;
  }

  void _checkAnswer() {
    setState(() {
      _isCorrect = _userInput.toUpperCase() == _currentWord;
      _textController.clear();
      _userInput = '';

      if (_isCorrect) {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        // Add points to local score only
        _score += 10;
        _showSuccessPopup();
        _currentIndex++;
        Future.delayed(const Duration(milliseconds: 1000), () {
          _loadNewWord();
        });
      } else {
        // Play shake animation for wrong answer
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Try again!'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFFFF5A1A),
          ),
        );
      }
    });
  }

  void _showGameComplete() {
    // Add total score only when game is completed
    ScoreService.updateGameScore(_score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: 'Game Complete!',
        message: 'Great job! You\'ve mastered these words.',
        score: _score,
        success: true,
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _score = 0;
            _currentIndex = 0;
            _loadNewWord();
          });
        },
      ),
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Correct!',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+10 points',
                style: TextStyle(
                  color: const Color(0xFF141414).withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFF5A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Word Scramble',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Word ${_currentIndex + 1} of ${_words.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_score',
                              style: const TextStyle(
                                fontFamily: 'CraftworkGrotesk',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${((_currentIndex + 1) / _words.length * 100).toInt()}%',
                            style: const TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _words.length,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Unscramble this word:',
                style: TextStyle(
                  fontFamily: 'CraftworkGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF141414),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF5A1A).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCorrect
                          ? _bounceAnimation.value
                          : _scaleAnimation.value,
                      child: Transform.translate(
                        offset: Offset(
                          _isCorrect
                              ? 0
                              : _shakeAnimation.value *
                                  sin(_animationController.value * 3 * 3.14159),
                          0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _scrambledWord.split('').map((letter) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5A1A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      const Color(0xFFFF5A1A).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    color: Color(0xFF141414),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF5A1A).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hint:',
                      style: TextStyle(
                        color: const Color(0xFF141414).withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hint,
                      style: const TextStyle(
                        color: Color(0xFF141414),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _textController,
                onChanged: (value) {
                  setState(() {
                    _userInput = value;
                  });
                },
                onSubmitted: (_) => _userInput.isEmpty ? null : _checkAnswer(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF141414),
                ),
                decoration: InputDecoration(
                  hintText: 'Type your answer...',
                  hintStyle: TextStyle(
                    color: const Color(0xFFFF5A1A).withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFF5A1A).withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFFFF5A1A).withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFFFF5A1A).withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF5A1A),
                    ),
                  ),
                ),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.go,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
