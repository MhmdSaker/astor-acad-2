import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lottie/lottie.dart';
import '../../data/word_pool.dart';
import 'dart:ui';
import '../../theme/text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/score_service.dart';
import '../../widgets/game_completion_dialog.dart';

class WordSearchGame extends StatefulWidget {
  const WordSearchGame({super.key});

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  late List<String> _words;
  late List<List<String>> _grid;
  late List<bool> _foundWords;
  int _score = 0;
  final int _gridSize = 10;
  String _selectedWord = '';
  List<int> _selectedCells = [];
  late Set<int> _foundCells = {};

  @override
  void initState() {
    super.initState();
    final wordPairs = WordPool.getRandomWords(6);
    _words = wordPairs.map((pair) => pair['word']!).toList();
    _initializeGame();
  }

  void _initializeGame() {
    _grid = List.generate(_gridSize, (_) => List.filled(_gridSize, ''));
    _foundWords = List.filled(_words.length, false);
    _foundCells = {};

    // Place words in random positions
    final random = Random();
    for (var i = 0; i < _words.length; i++) {
      bool placed = false;
      while (!placed) {
        // Randomly choose between horizontal and vertical placement
        bool isHorizontal = random.nextBool();

        if (isHorizontal) {
          // Try to place horizontally
          int row = random.nextInt(_gridSize);
          int col = random.nextInt(_gridSize - _words[i].length + 1);
          bool canPlace = true;

          // Check if space is available horizontally
          for (var j = 0; j < _words[i].length; j++) {
            if (_grid[row][col + j].isNotEmpty) {
              canPlace = false;
              break;
            }
          }

          if (canPlace) {
            // Place the word horizontally
            for (var j = 0; j < _words[i].length; j++) {
              _grid[row][col + j] = _words[i][j];
            }
            placed = true;
          }
        } else {
          // Try to place vertically
          int row = random.nextInt(_gridSize - _words[i].length + 1);
          int col = random.nextInt(_gridSize);
          bool canPlace = true;

          // Check if space is available vertically
          for (var j = 0; j < _words[i].length; j++) {
            if (_grid[row + j][col].isNotEmpty) {
              canPlace = false;
              break;
            }
          }

          if (canPlace) {
            // Place the word vertically
            for (var j = 0; j < _words[i].length; j++) {
              _grid[row + j][col] = _words[i][j];
            }
            placed = true;
          }
        }
      }
    }

    // Fill empty spaces with random letters
    for (var i = 0; i < _gridSize; i++) {
      for (var j = 0; j < _gridSize; j++) {
        if (_grid[i][j].isEmpty) {
          _grid[i][j] = String.fromCharCode(random.nextInt(26) + 65);
        }
      }
    }
  }

  void _handleCellTap(int row, int col) {
    final index = row * _gridSize + col;
    setState(() {
      if (_selectedCells.contains(index)) {
        _selectedCells.clear();
        _selectedWord = '';
      } else {
        _selectedCells.add(index);

        // Check if cells form a valid line (horizontal or vertical)
        if (_selectedCells.length > 1) {
          List<int> sortedCells = List.from(_selectedCells)..sort();
          bool isHorizontal = true;
          bool isVertical = true;

          // Check if cells are in same row (horizontal)
          int firstRow = sortedCells[0] ~/ _gridSize;
          for (int cell in sortedCells) {
            if (cell ~/ _gridSize != firstRow) {
              isHorizontal = false;
              break;
            }
          }

          // Check if cells are in same column (vertical)
          if (!isHorizontal) {
            int firstCol = sortedCells[0] % _gridSize;
            for (int cell in sortedCells) {
              if (cell % _gridSize != firstCol) {
                isVertical = false;
                break;
              }
            }
          }

          // If cells form a valid line, build the word
          if (isHorizontal || isVertical) {
            _selectedWord = '';
            for (int cellIndex in sortedCells) {
              int r = cellIndex ~/ _gridSize;
              int c = cellIndex % _gridSize;
              _selectedWord += _grid[r][c];
            }

            // Check if selected word matches any word in the list
            for (var i = 0; i < _words.length; i++) {
              if (_selectedWord == _words[i] && !_foundWords[i]) {
                _foundWords[i] = true;
                _score += 10;
                _foundCells.addAll(_selectedCells);
                _showWordFound(_words[i]);
                break;
              }
            }
          } else {
            // If cells don't form a valid line, clear selection
            _selectedCells.clear();
            _selectedWord = '';
          }
        }
      }
    });
  }

  void _showWordFound(String word) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found "$word"! +10 points'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
    _selectedCells.clear();
    _selectedWord = '';

    // Check if all words are found
    if (_foundWords.every((found) => found)) {
      _showGameComplete();
    }
  }

  void _showGameComplete() async {
    // Add total score only when game is completed
    await ScoreService.updateGameScore(_score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameCompletionDialog(
        title: 'Word Hunter!',
        message: 'You found all the hidden words!',
        score: _score,
        success: true,
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _score = 0;
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
                            'Word Search',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_foundWords.where((found) => found).length} of ${_words.length} words found',
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
                            '${((_foundWords.where((found) => found).length) / _words.length * 100).toInt()}%',
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
                          value: _foundWords.where((found) => found).length /
                              _words.length,
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
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _words.length,
                  (index) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _foundWords[index]
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : const Color(0xFFFF5A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _foundWords[index]
                            ? const Color(0xFF4CAF50)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      _words[index],
                      style: TextStyle(
                        fontFamily: 'CraftworkGrotesk',
                        color: _foundWords[index]
                            ? const Color(0xFF4CAF50)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: _gridSize * _gridSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ _gridSize;
                    final col = index % _gridSize;
                    return GestureDetector(
                      onTap: () => _handleCellTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedCells.contains(index)
                              ? const Color(0xFF2F6FED)
                              : _foundCells.contains(index)
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : Colors.white,
                          border: Border.all(
                            color: _foundCells.contains(index)
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5A1A).withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            _grid[row][col],
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              color: _selectedCells.contains(index)
                                  ? Colors.white
                                  : _foundCells.contains(index)
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF141414),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
