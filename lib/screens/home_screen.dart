import 'package:flutter/material.dart';
import 'dart:math';
import '../components/section_card.dart';
import '../screens/chat_screen.dart';
import '../screens/practice_screen.dart';
import 'games_screen.dart';
import '../screens/leaderboard_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/score_service.dart';
import '../screens/profile_screen.dart';
import '../screens/voice_chat_screen.dart';
import '../screens/level_progress_screen.dart';
import '../screens/pronunciation_practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedLanguage = 'English';
  late ConfettiController _confettiController;
  bool _hasClaimedReward = false;
  int _streakDays = 0; // Changed to start at 0
  int _totalPoints = 0;
  DateTime? _lastLoginDate;

  // Add new streak-related constants
  static const Map<String, int> _streakTiers = {
    'Beginner': 1,
    'Consistent': 7,
    'Dedicated': 30,
    'Committed': 90,
    'Expert': 180,
    'Master': 365,
  };

  // Update daily rewards structure with incremental rewards
  static const Map<int, Map<String, dynamic>> _dailyRewards = {
    1: {
      'title': 'Day 1 - Welcome',
      'points': 10,
      'bonus': {'type': 'starter', 'value': 5},
      'description': 'Begin your journey!',
      'bonusDescription': '+5 Starter Bonus',
    },
    2: {
      'title': 'Day 2 - Momentum',
      'points': 20,
      'bonus': {'type': 'multiplier', 'value': 1.2},
      'description': 'Building your streak!',
      'bonusDescription': '+20% Point Boost',
    },
    3: {
      'title': 'Day 3 - Persistence',
      'points': 35,
      'bonus': {'type': 'xp', 'value': 1.3},
      'description': 'Halfway there!',
      'bonusDescription': '+30% XP Boost',
    },
    4: {
      'title': 'Day 4 - Dedication',
      'points': 50,
      'bonus': {'type': 'coins', 'value': 1.5},
      'description': 'Keep pushing!',
      'bonusDescription': '+50% Coin Earnings',
    },
    5: {
      'title': 'Day 5 - Consistency',
      'points': 70,
      'bonus': {'type': 'power', 'value': 2.0},
      'description': 'Almost there!',
      'bonusDescription': '2x Power Boost',
    },
    6: {
      'title': 'Day 6 - Excellence',
      'points': 100,
      'bonus': {'type': 'all', 'value': 2.5},
      'description': 'One day to go!',
      'bonusDescription': '2.5x All Rewards',
    },
    7: {
      'title': 'Day 7 - Achievement',
      'points': 150,
      'bonus': {'type': 'mega', 'value': 3.0},
      'description': 'Weekly streak complete!',
      'bonusDescription': '3x Mega Boost Pack',
    },
  };

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadStreakData();
    _loadPoints();
    _checkAndUpdateStreak(); // Add streak check on init
    // Refresh points every second
    Timer.periodic(const Duration(seconds: 1), (_) {
      _loadPoints();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _streakDays = prefs.getInt('streak_days') ?? 0;
      _hasClaimedReward = prefs.getBool(
              'claimed_streak_reward_${DateTime.now().toIso8601String().split('T')[0]}') ??
          false;
      final lastLoginStr = prefs.getString('last_login_date');
      _lastLoginDate =
          lastLoginStr != null ? DateTime.parse(lastLoginStr) : null;
    });
  }

  Future<void> _checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastLoginDate == null) {
      // First time login
      await _updateStreak(prefs, today, 1);
      return;
    }

    final lastLogin = DateTime(
      _lastLoginDate!.year,
      _lastLoginDate!.month,
      _lastLoginDate!.day,
    );

    final difference = today.difference(lastLogin).inDays;

    if (difference == 1) {
      // Consecutive day login
      await _updateStreak(prefs, today, _streakDays + 1);
    } else if (difference > 1) {
      // Streak broken
      await _updateStreak(prefs, today, 1);
    } else if (difference == 0) {
      // Same day login - no streak update needed
      await prefs.setString('last_login_date', today.toIso8601String());
    }
  }

  Future<void> _updateStreak(
      SharedPreferences prefs, DateTime loginDate, int newStreak) async {
    setState(() {
      _streakDays = newStreak;
      _lastLoginDate = loginDate;
      _hasClaimedReward = false;
    });

    await prefs.setInt('streak_days', newStreak);
    await prefs.setString('last_login_date', loginDate.toIso8601String());
    await prefs.remove(
        'claimed_streak_reward_${loginDate.toIso8601String().split('T')[0]}');
  }

  Future<void> _loadPoints() async {
    if (!mounted) return;

    final gameScore = await ScoreService.getGameScore();
    final practiceScore = await ScoreService.getPracticeScore();

    setState(() {
      _totalPoints = gameScore + practiceScore;
    });
  }

  Future<void> _claimStreakReward() async {
    if (_hasClaimedReward) return;

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();

    // Calculate reward points based on streak
    int rewardPoints = _calculateRewardPoints();

    await ScoreService.updatePracticeScore(rewardPoints);

    setState(() {
      _hasClaimedReward = true;
    });

    await prefs.setBool('claimed_streak_reward_$today', true);
    await _loadPoints();

    _confettiController.play();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Congratulations! +$rewardPoints points added to your score!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _calculateRewardPoints() {
    final currentDayReward = _getCurrentDayReward();
    int basePoints = currentDayReward['points'] as int;
    Map<String, dynamic> bonus =
        currentDayReward['bonus'] as Map<String, dynamic>;

    // Calculate streak multiplier
    double streakMultiplier = 1.0;
    if (_streakDays >= 365)
      streakMultiplier = 5.0;
    else if (_streakDays >= 180)
      streakMultiplier = 4.0;
    else if (_streakDays >= 90)
      streakMultiplier = 3.0;
    else if (_streakDays >= 30)
      streakMultiplier = 2.0;
    else if (_streakDays >= 7) streakMultiplier = 1.5;

    // Apply bonus based on type
    double bonusMultiplier = 1.0;
    switch (bonus['type']) {
      case 'multiplier':
      case 'xp':
      case 'coins':
      case 'power':
      case 'all':
      case 'mega':
        bonusMultiplier = bonus['value'];
        break;
      case 'starter':
        basePoints += bonus['value'] as int;
        break;
    }

    // Calculate weekly streak bonus (additional bonus for completing weeks)
    int completedWeeks = (_streakDays - 1) ~/ 7;
    double weeklyBonus =
        1.0 + (completedWeeks * 0.1); // 10% extra per completed week

    // Add small random bonus (1-20%)
    double randomBonus = 1.0 + (Random().nextDouble() * 0.2);

    // Calculate final points
    double finalPoints = basePoints *
        streakMultiplier *
        bonusMultiplier *
        weeklyBonus *
        randomBonus;

    return finalPoints.round();
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

  int _calculateLevel() {
    // Base points needed for first level
    int basePoints = 100;
    // How much more points each level needs (20% increase per level)
    double increaseRate = 0.2;

    int currentPoints = _totalPoints;
    int level = 0;
    int pointsNeeded = basePoints;

    while (currentPoints >= pointsNeeded) {
      currentPoints -= pointsNeeded;
      level++;
      // Increase points needed for next level by 20%
      pointsNeeded = (basePoints * (1 + (increaseRate * level))).round();
    }

    return level + 1; // Add 1 since levels start at 1
  }

  double _calculateProgressToNextLevel() {
    int basePoints = 100;
    double increaseRate = 0.2;

    int currentPoints = _totalPoints;
    int level = 0;
    int pointsNeeded = basePoints;

    // Find current level's required points
    while (currentPoints >= pointsNeeded) {
      currentPoints -= pointsNeeded;
      level++;
      pointsNeeded = (basePoints * (1 + (increaseRate * level))).round();
    }

    // Calculate progress percentage to next level
    return currentPoints / pointsNeeded;
  }

  int _getPointsNeededForNextLevel() {
    int basePoints = 100;
    double increaseRate = 0.2;

    int currentPoints = _totalPoints;
    int level = 0;
    int pointsNeeded = basePoints;

    while (currentPoints >= pointsNeeded) {
      currentPoints -= pointsNeeded;
      level++;
      pointsNeeded = (basePoints * (1 + (increaseRate * level))).round();
    }

    return pointsNeeded - currentPoints;
  }

  Future<Map<String, int>> _getScoreBreakdown() async {
    final gameScore = await ScoreService.getGameScore();
    final practiceScore = await ScoreService.getPracticeScore();
    return {
      'games': gameScore,
      'practice': practiceScore,
      'total': gameScore + practiceScore,
    };
  }

  // Add method to get current day's reward
  Map<String, dynamic> _getCurrentDayReward() {
    final int currentDay = (_streakDays % 7) + 1;
    return _dailyRewards[currentDay] ?? _dailyRewards[1]!;
  }

  // Add method to get bonus description with current multipliers
  String _getCurrentBonusDescription() {
    final currentReward = _getCurrentDayReward();
    final baseBonus = currentReward['bonusDescription'] as String;

    // Calculate weekly bonus
    int completedWeeks = (_streakDays - 1) ~/ 7;
    if (completedWeeks > 0) {
      return '$baseBonus + ${(completedWeeks * 10)}% Weekly Bonus';
    }

    return baseBonus;
  }

  // Update the streak section in the build method
  Widget _buildStreakSection() {
    final currentReward = _getCurrentDayReward();
    final nextDay = (_streakDays % 7) + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5A1A).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_streakDays} ${_streakDays == 1 ? 'day' : 'days'} streak!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStreakDisplayText(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStreakTierTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add daily reward info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentReward['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.card_giftcard,
                        color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Bonus: ${_getCurrentBonusDescription()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: nextDay / 7,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day $nextDay of 7',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_hasClaimedReward) ...[
            _buildClaimButton(currentReward),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reward claimed! Come back tomorrow',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Update the claim reward button text
  Widget _buildClaimButton(Map<String, dynamic> currentReward) {
    return ElevatedButton(
      onPressed: _claimStreakReward,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF5A1A),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Claim ${_calculateRewardPoints()} points!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getCurrentBonusDescription(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Update the build method to use the new streak section
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0EB),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: const DecorationImage(
                                      image: AssetImage('assets/profile.png'),
                                      fit: BoxFit.cover,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFF5A1A),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Robert Walker',
                                  style: TextStyle(
                                    color: const Color(0xFF141414),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LevelProgressScreen(
                                              totalPoints: _totalPoints,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            '${_getLevelName(_calculateLevel())} - Level ${_calculateLevel()}',
                                            style: TextStyle(
                                              color: const Color(0xFF141414)
                                                  .withOpacity(0.7),
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${_getPointsNeededForNextLevel()} pts to next)',
                                            style: TextStyle(
                                              color: const Color(0xFF141414)
                                                  .withOpacity(0.5),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: const Color(0xFF141414)
                                                .withOpacity(0.5),
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A1A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              final scores = await _getScoreBreakdown();
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text(
                                      'Points Breakdown',
                                      style: TextStyle(
                                        color: Color(0xFF141414),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildScoreRow(
                                            'Games', scores['games']!),
                                        const SizedBox(height: 8),
                                        _buildScoreRow(
                                            'Practice', scores['practice']!),
                                        const Divider(),
                                        _buildScoreRow(
                                            'Total', scores['total']!,
                                            isTotal: true),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(
                                            color: Color(0xFFFF5A1A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 80),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.diamond_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatScore(_totalPoints),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildStreakSection(),
                    const SizedBox(height: 32),
                    // Header with Leaderboard Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular languages',
                          style: TextStyle(
                            color: const Color(0xFF141414),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaderboardScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A1A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.leaderboard,
                                  color: const Color(0xFFFF5A1A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Leaderboard',
                                  style: TextStyle(
                                    color: Color(0xFFFF5A1A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildLanguageButton('assets/flags/unitedstates.png',
                              'English', selectedLanguage == 'English'),
                          _buildLanguageButton('assets/flags/spain.png',
                              'Spanish', selectedLanguage == 'Spanish'),
                          _buildLanguageButton('assets/flags/italy.png',
                              'Italian', selectedLanguage == 'Italian'),
                          _buildLanguageButton('assets/flags/germany.png',
                              'German', selectedLanguage == 'German'),
                          _buildLanguageButton('assets/flags/flag.png',
                              'French', selectedLanguage == 'French'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SectionCard(
                      title: 'Practice',
                      subtitle: 'Learn to say \'I can see you\' in French',
                      imagePath: 'assets/practice.jpg',
                      backgroundColor: const Color(0xFFE8F5E9),
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PracticeScreen(),
                          ),
                        );
                      },
                    ),
                    SectionCard(
                      title: 'AI Chat',
                      subtitle: 'Have a conversation with AI',
                      imagePath: 'assets/ai_chat.jpg',
                      backgroundColor: const Color(0xFFE3F2FD),
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF2F6FED),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(),
                          ),
                        );
                      },
                    ),
                    SectionCard(
                      title: 'Games',
                      subtitle: 'Learn and play games at the same time',
                      imagePath: 'assets/games.jpg',
                      backgroundColor: const Color(0xFFFFF3E0),
                      icon: Icons.sports_esports_rounded,
                      iconColor: const Color(0xFFFFA726),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GamesScreen(),
                          ),
                        );
                      },
                    ),
                    SectionCard(
                      title: 'Voice Chat',
                      subtitle: 'Have a continuous voice conversation',
                      imagePath: 'assets/voice_chat.jpg',
                      backgroundColor: const Color(0xFFE3F2FD),
                      icon: Icons.mic_rounded,
                      iconColor: const Color(0xFF2F6FED),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VoiceChatScreen(),
                          ),
                        );
                      },
                    ),
                    SectionCard(
                      title: 'Pronunciation Practice',
                      subtitle: 'Practice with movie scenes',
                      imagePath: 'assets/pronunciation.jpg',
                      backgroundColor: const Color(0xFFE8F5E9),
                      icon: Icons.record_voice_over_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PronunciationPracticeScreen(
                                    level: 'Beginner'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.05,
              shouldLoop: false,
              colors: const [
                Color(0xFFFF5A1A),
                Color(0xFF4CAF50),
                Color(0xFF2F6FED),
                Color(0xFFFFA726),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
      String flagPath, String language, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFFF7F0EB),
              title: Text(
                'Select Language',
                style: TextStyle(
                  color: const Color(0xFF141414),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Would you like to switch to $language?',
                style: TextStyle(
                  color: const Color(0xFF141414),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedLanguage = language;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Select'),
                ),
              ],
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: language == selectedLanguage
                  ? const Color(0xFFFF5A1A)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                flagPath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int points, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF141414),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: const Color(0xFFFF5A1A),
              size: isTotal ? 20 : 16,
            ),
            const SizedBox(width: 4),
            Text(
              points.toString(),
              style: TextStyle(
                color: const Color(0xFF141414),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  // Update the streak section in the build method
  String _getStreakTierTitle() {
    for (var entry in _streakTiers.entries.toList().reversed) {
      if (_streakDays >= entry.value) {
        return entry.key;
      }
    }
    return 'Beginner';
  }

  // Update the streak display text
  String _getStreakDisplayText() {
    if (_streakDays <= 1) {
      return "Start your learning journey!";
    } else if (_streakDays < 7) {
      return "Building momentum!";
    } else if (_streakDays < 30) {
      return "Keep going strong!";
    } else if (_streakDays < 90) {
      return "You're on fire!";
    } else if (_streakDays < 180) {
      return "Unstoppable!";
    } else {
      return "Legendary streak!";
    }
  }
}
