import 'package:flutter/material.dart';
import '../services/score_service.dart';

class LevelProgressScreen extends StatefulWidget {
  final int totalPoints;
  
  const LevelProgressScreen({
    super.key,
    required this.totalPoints,
  });

  @override
  State<LevelProgressScreen> createState() => _LevelProgressScreenState();
}

class _LevelProgressScreenState extends State<LevelProgressScreen> {
  // Constants for level calculation
  static const int basePoints = 100;
  static const double increaseRate = 0.2;

  late final List<Map<String, dynamic>> _levelDetails;
  late final int _currentLevel;
  late final double _currentProgress;
  late final int _pointsToNext;

  @override
  void initState() {
    super.initState();
    _calculateLevelDetails();
  }

  void _calculateLevelDetails() {
    _levelDetails = [];
    int currentPoints = widget.totalPoints;
    int level = 0;
    int pointsNeeded = basePoints;
    int accumulatedPoints = 0;

    // Calculate current level and create level details
    while (accumulatedPoints <= widget.totalPoints + 500) { // Show next 5 levels
      _levelDetails.add({
        'level': level + 1,
        'pointsNeeded': pointsNeeded,
        'totalPointsRequired': accumulatedPoints,
        'isCurrentLevel': accumulatedPoints <= widget.totalPoints && 
            widget.totalPoints < (accumulatedPoints + pointsNeeded),
      });
      
      accumulatedPoints += pointsNeeded;
      level++;
      pointsNeeded = (basePoints * (1 + (increaseRate * level))).round();
    }

    // Find current level and progress
    _currentLevel = _levelDetails.firstWhere((d) => d['isCurrentLevel'])['level'];
    int currentLevelStart = _levelDetails[_currentLevel - 1]['totalPointsRequired'];
    int nextLevelPoints = _levelDetails[_currentLevel]['totalPointsRequired'];
    _currentProgress = (widget.totalPoints - currentLevelStart) / 
        (nextLevelPoints - currentLevelStart);
    _pointsToNext = nextLevelPoints - widget.totalPoints;
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Word Rookie';
      case 2:
        return 'Language Scout';
      case 3:
        return 'Vocab Explorer';
      case 4:
        return 'Word Warrior';
      case 5:
        return 'Language Knight';
      case 6:
        return 'Grammar Guardian';
      case 7:
        return 'Syntax Sorcerer';
      case 8:
        return 'Word Wizard';
      case 9:
        return 'Language Legend';
      case 10:
        return 'Linguistic Lord';
      default:
        if (level > 10 && level <= 15) return 'Word Master';
        if (level > 15 && level <= 20) return 'Language Sage';
        if (level > 20 && level <= 25) return 'Vocab Virtuoso';
        if (level > 25) return 'Language God';
        return 'Word Rookie';
    }
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
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
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
                            'Level Progress',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current Level: $_currentLevel',
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
                              '${widget.totalPoints}',
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
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Level Progress
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLevelName(_currentLevel),
                  style: const TextStyle(
                    fontFamily: 'CraftworkGrotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: const Color(0xFFFF5A1A).withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5A1A)),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_pointsToNext points needed for next level',
                  style: TextStyle(
                    color: const Color(0xFF1C1C1E).withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Level Progression List
          ...List.generate(_levelDetails.length, (index) {
            final levelDetail = _levelDetails[index];
            final isCurrentLevel = levelDetail['isCurrentLevel'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrentLevel
                      ? const Color(0xFFFF5A1A)
                      : Colors.grey.withOpacity(0.3),
                  width: isCurrentLevel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCurrentLevel
                          ? const Color(0xFFFF5A1A)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${levelDetail['level']}',
                        style: TextStyle(
                          color: isCurrentLevel ? Colors.white : Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLevelName(levelDetail['level']),
                          style: TextStyle(
                            color: const Color(0xFF1C1C1E),
                            fontSize: 18,
                            fontWeight:
                                isCurrentLevel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          'Required: ${levelDetail['totalPointsRequired']} points',
                          style: TextStyle(
                            color: const Color(0xFF1C1C1E).withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentLevel)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A1A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Color(0xFFFF5A1A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
} 