import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lottie/lottie.dart';
import '../../widgets/game_completion_dialog.dart';
import '../../data/word_pool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../theme/text_styles.dart';
import '../../services/score_service.dart';

class HangmanGame extends StatefulWidget {
  const HangmanGame({super.key});

  @override
  State<HangmanGame> createState() => _HangmanGameState();
}

class _HangmanGameState extends State<HangmanGame> {
  late List<Map<String, String>> _words;
  late String _word;
  late String _hint;
  late List<bool> _guessedLetters;
  final Set<String> _usedLetters = {};
  int _wrongGuesses = 0;
  int _score = 0;
  final int _maxWrongGuesses = 6;

  @override
  void initState() {
    super.initState();
    _words = WordPool.getRandomWords(10); // Get 10 random words
    _initializeGame();
  }

  void _initializeGame() {
    final randomIndex = Random().nextInt(_words.length);
    final randomWord = _words[randomIndex];
    _word = randomWord['word']!;
    _hint = randomWord['hint']!;
    _guessedLetters = List.filled(_word.length, false);
    _usedLetters.clear();
    _wrongGuesses = 0;
  }

  void _handleLetterPress(String letter) {
    if (_usedLetters.contains(letter)) return;

    setState(() {
      _usedLetters.add(letter);
      if (_word.contains(letter)) {
        // Correct guess
        for (var i = 0; i < _word.length; i++) {
          if (_word[i] == letter) {
            _guessedLetters[i] = true;
          }
        }
        // Add points to local score only
        _score += 2;
      } else {
        _wrongGuesses++;
      }

      // Check win condition
      if (_guessedLetters.every((guessed) => guessed)) {
        _showGameComplete(true);
      }
      // Check lose condition
      else if (_wrongGuesses >= _maxWrongGuesses) {
        _showGameComplete(false);
      }
    });
  }

  Future<void> _updateTotalScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTotal = prefs.getInt('total_score') ?? 0;
    await prefs.setInt('total_score', currentTotal + score);
  }

  void _showGameComplete(bool won) async {
    if (won) {
      // Only update score if player won
      await ScoreService.updateGameScore(_score);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: won ? 'Word Master!' : 'Game Over',
        message: won
            ? 'You\'ve successfully guessed the word!'
            : 'The word was: $_word',
        score: _score,
        success: won,
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _initializeGame();
          });
        },
      ),
    );
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
                            'Hangman',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Attempts left: ${_maxWrongGuesses - _wrongGuesses}',
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
                            '${((_maxWrongGuesses - _wrongGuesses) / _maxWrongGuesses * 100).toInt()}%',
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
                          value: (_maxWrongGuesses - _wrongGuesses) /
                              _maxWrongGuesses,
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF5A1A).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5A1A).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Hint: $_hint',
                    style: const TextStyle(
                      fontFamily: 'CraftworkGrotesk',
                      color: Color(0xFF1C1C1E),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _word.length,
                      (index) => Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _guessedLetters[index] ? _word[index] : '_',
                            style: const TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF5A1A).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5A1A).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  26,
                  (index) => SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed:
                          _usedLetters.contains(String.fromCharCode(65 + index))
                              ? null
                              : () => _handleLetterPress(
                                  String.fromCharCode(65 + index)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFFF5A1A),
                        disabledBackgroundColor:
                            const Color(0xFFFF5A1A).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          fontFamily: 'CraftworkGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
