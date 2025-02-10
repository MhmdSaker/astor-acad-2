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
import 'dart:convert';
import 'pronunciation_practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedLanguage = 'English';
  String userName = 'Robert Walker';
  String userBio = 'Language enthusiast';
  String location = 'New York, USA';
  String nativeLanguage = 'English';
  String learningGoal = 'Become fluent in multiple languages';
  late ConfettiController _confettiController;
  bool _hasClaimedReward = false;
  int _streakDays = 0; // Changed to start at 0
  int _totalPoints = 0;
  DateTime? _lastRewardTime;
  Timer? _rewardTimer;

  // Add new streak-related constants
  static const Map<String, int> _streakTiers = {
    'Beginner': 1,
    'Consistent': 7,
    'Dedicated': 30,
    'Committed': 90,
    'Expert': 180,
    'Master': 365,
  };

  // Update daily rewards structure with more reasonable rewards
  static const Map<int, Map<String, dynamic>> _dailyRewards = {
    1: {
      'title': 'Day 1 - Welcome',
      'points': 50,
      'bonus': {'type': 'starter', 'value': 10},
      'description': 'Begin your journey!',
      'bonusDescription': '+10 Starter Bonus',
    },
    2: {
      'title': 'Day 2 - Momentum',
      'points': 60,
      'bonus': {'type': 'multiplier', 'value': 1.1},
      'description': 'Building your streak!',
      'bonusDescription': '+10% Point Boost',
    },
    3: {
      'title': 'Day 3 - Persistence',
      'points': 75,
      'bonus': {'type': 'xp', 'value': 1.15},
      'description': 'Halfway there!',
      'bonusDescription': '+15% XP Boost',
    },
    4: {
      'title': 'Day 4 - Dedication',
      'points': 90,
      'bonus': {'type': 'multiplier', 'value': 1.2},
      'description': 'Keep pushing!',
      'bonusDescription': '+20% Point Boost',
    },
    5: {
      'title': 'Day 5 - Consistency',
      'points': 100,
      'bonus': {'type': 'power', 'value': 1.25},
      'description': 'Almost there!',
      'bonusDescription': '+25% Power Boost',
    },
    6: {
      'title': 'Day 6 - Excellence',
      'points': 125,
      'bonus': {'type': 'all', 'value': 1.3},
      'description': 'One day to go!',
      'bonusDescription': '+30% All Rewards',
    },
    7: {
      'title': 'Day 7 - Achievement',
      'points': 150,
      'bonus': {'type': 'mega', 'value': 1.5},
      'description': 'Weekly streak complete!',
      'bonusDescription': '+50% Mega Boost Pack',
    },
  };

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadUserData();
    _loadStreakData();
    _initializeRewardTimer();
    Timer.periodic(const Duration(seconds: 1), (_) async {
      await _loadPoints();
    });
  }

  @override
  void dispose() {
    _rewardTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Robert Walker';
      userBio = prefs.getString('user_bio') ?? 'Language enthusiast';
      location = prefs.getString('location') ?? 'New York, USA';
      nativeLanguage = prefs.getString('native_language') ?? 'English';
      learningGoal = prefs.getString('learning_goal') ??
          'Become fluent in multiple languages';
    });
  }

  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRewardTimeStr = prefs.getString('last_reward_time');
    final savedStreak = prefs.getInt('streak_days') ?? 0;

    setState(() {
      _streakDays = savedStreak;
      _lastRewardTime =
          lastRewardTimeStr != null ? DateTime.parse(lastRewardTimeStr) : null;
    });

    // Check if reward is available
    if (_lastRewardTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastRewardTime!);

      setState(() {
        _hasClaimedReward = difference.inHours < 24;
      });

      // Set up timer for next reward
      if (difference.inHours < 24) {
        final remainingTime = const Duration(hours: 24) - difference;
        _rewardTimer?.cancel();
        _rewardTimer = Timer(remainingTime, () {
          if (mounted) {
            setState(() => _hasClaimedReward = false);
          }
        });
      }
    }
  }

  void _initializeRewardTimer() {
    if (_lastRewardTime != null) {
      final timeSinceLastReward = DateTime.now().difference(_lastRewardTime!);
      final remainingTime = const Duration(hours: 24) - timeSinceLastReward;

      if (remainingTime.isNegative) {
        _hasClaimedReward = false;
      } else {
        _rewardTimer = Timer(remainingTime, () {
          setState(() => _hasClaimedReward = false);
        });
      }
    }
  }

  Future<void> _checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (_lastRewardTime == null) {
      // First time login
      await _updateStreak(prefs, now, 1);
      return;
    }

    final hoursSinceLastReward = now.difference(_lastRewardTime!).inHours;

    if (hoursSinceLastReward < 24) {
      // Same day - keep streak
      return;
    } else if (hoursSinceLastReward <= 48) {
      // Next day within 48 hours - increment streak
      await _updateStreak(prefs, now, _streakDays + 1);
    } else {
      // More than 48 hours - reset streak
      await _updateStreak(prefs, now, 1);
    }
  }

  Future<void> _updateStreak(
      SharedPreferences prefs, DateTime now, int newStreak) async {
    setState(() {
      _streakDays = newStreak;
      _lastRewardTime = now;
      _hasClaimedReward = false;
    });

    await prefs.setInt('streak_days', newStreak);
    await prefs.setString('last_reward_time', now.toIso8601String());
  }

  Future<void> _loadPoints() async {
    if (!mounted) return;

    final gameScore = await ScoreService.getGameScore();
    final practiceScore = await ScoreService.getPracticeScore();

    setState(() {
      _totalPoints = gameScore + practiceScore;
    });
  }

  Future<void> _claimDailyReward() async {
    if (_hasClaimedReward) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Check if this is first claim or if enough time has passed
    if (_lastRewardTime == null) {
      // First time claiming
      await _updateStreak(prefs, now, 1);
    } else {
      final hoursSinceLastReward = now.difference(_lastRewardTime!).inHours;

      if (hoursSinceLastReward < 24) {
        // Too early to claim
        return;
      } else if (hoursSinceLastReward <= 48) {
        // Within 48 hours - maintain streak
        await _updateStreak(prefs, now, _streakDays + 1);
      } else {
        // More than 48 hours - reset streak
        await _updateStreak(prefs, now, 1);
      }
    }

    // Calculate and add points
    final points = _calculateRewardPoints();
    await ScoreService.addPoints(points);

    // Update reward status
    setState(() {
      _hasClaimedReward = true;
      _lastRewardTime = now;
    });

    // Save last reward time
    await prefs.setString('last_reward_time', now.toIso8601String());

    // Set up timer for next reward
    _rewardTimer?.cancel();
    _rewardTimer = Timer(const Duration(hours: 24), () {
      if (mounted) {
        setState(() => _hasClaimedReward = false);
      }
    });

    // Show celebration
    _confettiController.play();
  }

  int _calculateRewardPoints() {
    // Base points for daily reward
    int basePoints = 50;

    // Bonus points based on streak
    if (_streakDays >= 7) basePoints += 20; // Week bonus
    if (_streakDays >= 30) basePoints += 50; // Month bonus
    if (_streakDays >= 100) basePoints += 100; // Century bonus

    // Multiplier based on streak tier
    double multiplier = 1.0;
    if (_streakDays >= 365)
      multiplier = 2.0; // Master
    else if (_streakDays >= 180)
      multiplier = 1.8; // Expert
    else if (_streakDays >= 90)
      multiplier = 1.6; // Committed
    else if (_streakDays >= 30)
      multiplier = 1.4; // Dedicated
    else if (_streakDays >= 7) multiplier = 1.2; // Consistent

    return (basePoints * multiplier).round();
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
    // Get the current day in the week (1-7)
    final dayInWeek = _streakDays % 7;
    final day = dayInWeek == 0 ? 7 : dayInWeek;

    return _dailyRewards[day] ?? _dailyRewards[1]!;
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
      onPressed: _claimDailyReward,
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
                                onTap: () async {
                                  await _navigateToProfile();
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
                                  userName,
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
                      title: 'Pronunciation',
                      subtitle: 'Practice speaking with movie scenes',
                      imagePath: 'assets/pronunciation.jpg',
                      backgroundColor: const Color(0xFFF3E5F5),
                      onTap: () {
                        // Add ripple effect
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Pronunciation Practice...'),
                            duration: Duration(milliseconds: 500),
                            backgroundColor: Color(0xFFFF5A1A),
                          ),
                        );

                        // Navigate with fade transition
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation,
                                    secondaryAnimation) =>
                                const PronunciationPracticeScreen(
                                    level: 'Beginner'),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                    SectionCard(
                      title: 'AI Chat',
                      subtitle:
                          'Chat with our AI to practice your language skills',
                      imagePath: 'assets/ai_chat.jpg',
                      backgroundColor: const Color(0xFFE3F2FD),
                      onTap: () {
                        // Add ripple effect
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening AI Chat...'),
                            duration: Duration(milliseconds: 500),
                            backgroundColor: Color(0xFFFF5A1A),
                          ),
                        );

                        // Navigate with fade transition
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ChatScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                    SectionCard(
                      title: 'Games',
                      subtitle: 'Learn and play games at the same time',
                      imagePath: 'assets/games.jpg',
                      backgroundColor: const Color(0xFFFFF3E0),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VoiceChatScreen(),
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

  // Add this method to handle account navigation with edit capabilities
  Future<void> _navigateToProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final initialData = {
      'userName': prefs.getString('user_name') ?? 'Robert Walker',
      'userBio': prefs.getString('user_bio') ?? 'Language enthusiast',
      'location': prefs.getString('location') ?? 'New York, USA',
      'nativeLanguage': prefs.getString('native_language') ?? 'English',
      'learningGoal': prefs.getString('learning_goal') ??
          'Become fluent in multiple languages',
      'learningGoals': await _getLearningGoals(),
      'preferredLanguages': await _getPreferredLanguages(),
      'studyReminders': await _getStudyReminders(),
      'proficiencyLevels': await _getProficiencyLevels(),
      'learningStyle': await _getLearningStyle(),
    };

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          onUpdateProfile: _handleProfileUpdate,
          initialData: initialData,
        ),
      ),
    );
  }

  // Add these methods to manage profile data
  Future<Map<String, dynamic>> _getLearningGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGoals = prefs.getString('learning_goals');
    if (savedGoals != null) {
      return Map<String, dynamic>.from(jsonDecode(savedGoals));
    }
    return {
      'dailyGoal': 20,
      'weeklyTarget': 5,
      'focusAreas': ['Speaking', 'Vocabulary', 'Grammar'],
      'targetLevel': 'B2',
    };
  }

  Future<List<String>> _getPreferredLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguages = prefs.getStringList('preferred_languages');
    return savedLanguages ?? ['English', 'Spanish', 'French'];
  }

  Future<Map<String, dynamic>> _getStudyReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedReminders = prefs.getString('study_reminders');
    if (savedReminders != null) {
      return Map<String, dynamic>.from(jsonDecode(savedReminders));
    }
    return {
      'dailyReminder': true,
      'weeklyProgress': true,
      'streakAlert': true,
      'customTime': '08:00',
    };
  }

  Future<Map<String, String>> _getProficiencyLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevels = prefs.getString('proficiency_levels');
    if (savedLevels != null) {
      return Map<String, String>.from(jsonDecode(savedLevels));
    }
    return {
      'English': 'B2',
      'Spanish': 'A2',
      'French': 'A1',
    };
  }

  Future<Map<String, dynamic>> _getLearningStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStyle = prefs.getString('learning_style');
    if (savedStyle != null) {
      return Map<String, dynamic>.from(jsonDecode(savedStyle));
    }
    return {
      'preferred': 'Visual',
      'pacePreference': 'Moderate',
      'practiceStyle': 'Interactive',
      'feedbackFrequency': 'High',
    };
  }

  // Update the profile handler
  Future<void> _handleProfileUpdate(Map<String, dynamic> updatedData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save updated profile data
    await prefs.setString('user_name', updatedData['userName']);
    await prefs.setString('user_bio', updatedData['userBio']);
    await prefs.setString('location', updatedData['location']);
    await prefs.setString('native_language', updatedData['nativeLanguage']);
    await prefs.setString('learning_goal', updatedData['learningGoal']);
    await prefs.setString(
        'learning_goals', jsonEncode(updatedData['learningGoals']));
    await prefs.setStringList('preferred_languages',
        List<String>.from(updatedData['preferredLanguages']));
    await prefs.setString(
        'study_reminders', jsonEncode(updatedData['studyReminders']));
    await prefs.setString(
        'proficiency_levels', jsonEncode(updatedData['proficiencyLevels']));
    await prefs.setString(
        'learning_style', jsonEncode(updatedData['learningStyle']));

    // Update local state
    setState(() {
      selectedLanguage = updatedData['preferredLanguages'][0];
      userName = updatedData['userName'];
      userBio = updatedData['userBio'];
      location = updatedData['location'];
      nativeLanguage = updatedData['nativeLanguage'];
      learningGoal = updatedData['learningGoal'];
    });
  }
}
