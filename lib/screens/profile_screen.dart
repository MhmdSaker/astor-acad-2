import 'package:flutter/material.dart';
import '../services/score_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalScore = 0;
  int _gamesScore = 0;
  int _practiceScore = 0;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final total = await ScoreService.getTotalScore();
    final games = await ScoreService.getGameScore();
    final practice = await ScoreService.getPracticeScore();
    setState(() {
      _totalScore = total;
      _gamesScore = games;
      _practiceScore = practice;
    });
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
    const pointsPerLevel = 100;
    return (_totalScore / pointsPerLevel).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final level = _calculateLevel();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5A1A),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'CraftworkGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5A1A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/profile.png'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Robert Walker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_getLevelName(level)} - Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      color: Color(0xFF141414),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Score',
                          _totalScore.toString(),
                          Icons.stars_rounded,
                          const Color(0xFFFF5A1A),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Games Score',
                          _gamesScore.toString(),
                          Icons.games,
                          const Color(0xFF2F6FED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Practice Score',
                          _practiceScore.toString(),
                          Icons.school,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Streak',
                          '14 Days',
                          Icons.local_fire_department,
                          const Color(0xFFFFA726),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Color(0xFF141414),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    'Edit Profile',
                    Icons.edit,
                    onTap: () {
                      // Handle edit profile
                    },
                  ),
                  _buildSettingTile(
                    'Notifications',
                    Icons.notifications,
                    onTap: () {
                      // Handle notifications
                    },
                  ),
                  _buildSettingTile(
                    'Language',
                    Icons.language,
                    onTap: () {
                      // Handle language settings
                    },
                  ),
                  _buildSettingTile(
                    'Privacy Policy',
                    Icons.privacy_tip,
                    onTap: () {
                      // Handle privacy policy
                    },
                  ),
                  _buildSettingTile(
                    'Log Out',
                    Icons.logout,
                    color: const Color(0xFFE53935),
                    onTap: () {
                      // Handle logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, IconData icon,
      {Color? color, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: color ?? const Color(0xFF141414),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? const Color(0xFF141414),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? const Color(0xFF141414).withOpacity(0.5),
      ),
    );
  }
} 