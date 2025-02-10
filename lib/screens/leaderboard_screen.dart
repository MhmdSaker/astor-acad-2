import 'package:flutter/material.dart';
import 'dart:async';
import '../services/score_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  bool isWeekly = true;
  late String _userName = '';
  late int _userScore = 0;
  late Timer _updateTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> _leaderboardData = [
    {
      'name': 'Emma Chen',
      'score': 850,
      'level': 'Advanced',
      'streak': 15,
      'trend': 0.0
    },
    {
      'name': 'Lucas Silva',
      'score': 720,
      'level': 'Intermediate',
      'streak': 12,
      'trend': 0.0
    },
    {
      'name': 'Sophie Kim',
      'score': 680,
      'level': 'Intermediate',
      'streak': 8,
      'trend': 0.0
    },
    {
      'name': 'Alex Patel',
      'score': 550,
      'level': 'Beginner',
      'streak': 5,
      'trend': 0.0
    },
    {
      'name': 'Maria Garcia',
      'score': 480,
      'level': 'Beginner',
      'streak': 4,
      'trend': 0.0
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupAnimation();
    _startPeriodicUpdates();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _startPeriodicUpdates() {
    // Update scores every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateLeaderboardScores();
      }
    });
  }

  void _updateLeaderboardScores() {
    final random = Random();
    setState(() {
      for (var data in _leaderboardData) {
        if (data['name'] != _userName) {
          // Don't modify user's score
          // Small random score changes (-20 to +30 points)
          final change = random.nextInt(51) - 20;
          data['score'] += change;
          data['trend'] = change.toDouble();
        }
      }
      _sortLeaderboard();
    });
  }

  void _sortLeaderboard() {
    _leaderboardData.sort((a, b) => b['score'].compareTo(a['score']));
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final score = await ScoreService.getTotalScore();

    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
        _userScore = score;

        // Remove any existing user entry
        _leaderboardData.removeWhere((entry) => entry['name'] == _userName);

        // Add user's current data
        _leaderboardData.add({
          'name': _userName,
          'score': _userScore,
          'level': _calculateLevel(_userScore),
          'streak': prefs.getInt('streak_days') ?? 0,
          'trend': 0.0,
          'isUser': true,
        });

        _sortLeaderboard();
      });
    }
  }

  String _calculateLevel(int score) {
    if (score >= 800) return 'Expert';
    if (score >= 600) return 'Advanced';
    if (score >= 400) return 'Intermediate';
    return 'Beginner';
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF5A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildToggleButtons(),
          const SizedBox(height: 24),
          _buildTopThree(),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _leaderboardData.length,
                itemBuilder: (context, index) {
                  final entry = _leaderboardData[index];
                  return _buildLeaderboardItem(
                    entry['name'],
                    entry['score'].toString(),
                    index + 1,
                    entry['trend'] > 0,
                    entry['trend'].abs(),
                    isUser: entry['name'] == _userName,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildToggleButton('Weekly', isWeekly),
          _buildToggleButton('All Time', !isWeekly),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isWeekly = text == 'Weekly'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5A1A) : Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFFF5A1A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopThree() {
    if (_leaderboardData.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_leaderboardData.length > 1)
          _buildTopPosition(1, _leaderboardData[1]),
        _buildTopPosition(0, _leaderboardData[0]),
        if (_leaderboardData.length > 2)
          _buildTopPosition(2, _leaderboardData[2]),
      ],
    );
  }

  Widget _buildTopPosition(int position, Map<String, dynamic> data) {
    final isFirst = position == 0;
    final height = isFirst ? 160.0 : 120.0;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2 * position, 0.6 + 0.2 * position,
            curve: Curves.easeOut),
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: isFirst ? 40 : 30,
            backgroundColor: Colors.white,
            child: Text(
              data['name'][0],
              style: TextStyle(
                color: const Color(0xFFFF5A1A),
                fontSize: isFirst ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['name'],
            style: const TextStyle(color: Colors.white),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data['score']} pts',
              style: const TextStyle(
                color: Color(0xFFFF5A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
      String name, String points, int position, bool isUp, double change,
      {bool isUser = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFFF5A1A).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isUser ? const Color(0xFFFF5A1A) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            position.toString().padLeft(2, '0'),
            style: TextStyle(
              color: const Color(0xFF141414).withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: isUser
                ? const Color(0xFFFF5A1A)
                : const Color(0xFFFF5A1A).withOpacity(0.1),
            child: Text(
              name[0],
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFFFF5A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: const Color(0xFF141414),
                fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points pts',
                style: const TextStyle(
                  color: Color(0xFFFF5A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (change > 0)
                Text(
                  '${isUp ? '+' : '-'}${change.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isUp ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
