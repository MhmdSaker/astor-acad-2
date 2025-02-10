import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import '../../widgets/game_completion_dialog.dart';
import '../../data/word_pool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../../theme/text_styles.dart';
import '../../services/score_service.dart';

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame>
    with TickerProviderStateMixin {
  late List<Map<String, String>> _wordPairs;
  late List<Map<String, dynamic>> _cards;
  List<int> _selectedCards = [];
  List<int> _matchedCards = [];
  int _score = 0;
  bool _canFlip = true;
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;

  @override
  void initState() {
    super.initState();
    _wordPairs = WordPool.getRandomWords(6); // Get 6 random pairs
    _initializeGame();
    _initializeAnimations();
  }

  void _initializeGame() {
    // Create pairs of cards (word + meaning)
    _cards = [];
    for (var pair in _wordPairs) {
      _cards.add({
        'content': pair['word']!,
        'isWord': true,
        'isFlipped': false,
      });
      _cards.add({
        'content': pair['hint']!, // Using hint as meaning
        'isWord': false,
        'isFlipped': false,
      });
    }
    _cards.shuffle();
  }

  void _initializeAnimations() {
    _flipControllers = List.generate(
      _cards.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _flipAnimations = _flipControllers.map((controller) {
      return Tween<double>(begin: 0, end: 3.14159).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleCardTap(int index) {
    if (!_canFlip ||
        _matchedCards.contains(index) ||
        _selectedCards.contains(index)) {
      return;
    }

    _flipControllers[index].forward();
    setState(() {
      _cards[index]['isFlipped'] = true;
      _selectedCards.add(index);
    });

    if (_selectedCards.length == 2) {
      _canFlip = false;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final firstCard = _cards[_selectedCards[0]];
    final secondCard = _cards[_selectedCards[1]];

    // Check if one is a word and one is a meaning
    if (firstCard['isWord'] != secondCard['isWord']) {
      // Find the corresponding pair
      final wordCard = firstCard['isWord'] ? firstCard : secondCard;
      final meaningCard = firstCard['isWord'] ? secondCard : firstCard;

      // Check if they match
      final matchFound = _wordPairs.any((pair) =>
          pair['word'] == wordCard['content'] &&
          pair['hint'] == meaningCard['content']);

      if (matchFound) {
        setState(() {
          _matchedCards.addAll(_selectedCards);
          _score += 10;
        });

        // Check if all pairs are matched
        if (_matchedCards.length == _cards.length) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _showGameComplete();
          });
        }
      } else {
        // If no match, flip cards back after delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          for (var index in _selectedCards) {
            _flipControllers[index].reverse();
          }
        });
      }
    } else {
      // If both cards are same type (both words or both meanings), flip back
      Future.delayed(const Duration(milliseconds: 1000), () {
        for (var index in _selectedCards) {
          _flipControllers[index].reverse();
        }
      });
    }

    // Reset selected cards after a delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        for (var index in _selectedCards) {
          if (!_matchedCards.contains(index)) {
            _cards[index]['isFlipped'] = false;
          }
        }
        _selectedCards = [];
        _canFlip = true;
      });
    });
  }

  Future<void> _updateTotalScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTotal = prefs.getInt('total_score') ?? 0;
    await prefs.setInt('total_score', currentTotal + score);
  }

  void _showGameComplete() {
    // Add total score only when game is completed
    ScoreService.updateGameScore(_score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: 'Perfect Match!',
        message:
            'You\'ve matched all the words with their meanings!\nGreat job learning new vocabulary!',
        score: _score,
        success: true,
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _matchedCards = [];
            _selectedCards = [];
            _score = 0;
            _wordPairs = WordPool.getRandomWords(6);
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
                            'Memory Match',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_matchedCards.length ~/ 2} of ${_cards.length ~/ 2} pairs matched',
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
                            '${((_matchedCards.length ~/ 2) / (_cards.length ~/ 2) * 100).toInt()}%',
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
                          value: (_matchedCards.length ~/ 2) /
                              (_cards.length ~/ 2),
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
              child: Text(
                'Match each word with its meaning',
                style: TextStyle(
                  fontFamily: 'CraftworkGrotesk',
                  color: const Color(0xFF1C1C1E),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    return AnimatedBuilder(
      animation: _flipAnimations[index],
      builder: (context, child) {
        final isFlipped = _flipAnimations[index].value >= (3.14159 / 2);
        final rotationValue = _flipAnimations[index].value;
        final shouldMirror = rotationValue >= (3.14159 / 2);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(rotationValue),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _handleCardTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: _matchedCards.contains(index)
                    ? const Color(0xFF4CAF50)
                    : isFlipped
                        ? const Color(0xFFFF5A1A)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: _matchedCards.contains(index)
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : const Color(0xFFFF5A1A).withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Transform(
                  transform: Matrix4.identity()
                    ..rotateY(shouldMirror ? 3.14159 : 0),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      isFlipped ? _cards[index]['content'] : '?',
                      style: TextStyle(
                        fontFamily: 'CraftworkGrotesk',
                        color: isFlipped || _matchedCards.contains(index)
                            ? Colors.white
                            : const Color(0xFF141414),
                        fontSize: isFlipped ? 14 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
