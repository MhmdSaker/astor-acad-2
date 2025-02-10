import 'package:flutter/material.dart';
import '../services/score_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onUpdateProfile;
  final Map<String, dynamic> initialData;

  const ProfileScreen({
    Key? key,
    required this.onUpdateProfile,
    required this.initialData,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalScore = 0;
  int _gamesScore = 0;
  int _practiceScore = 0;
  late Map<String, dynamic> _profileData;
  final _formKey = GlobalKey<FormState>();
  late String _userName;
  String? _profileImagePath;
  late List<String> _interests;
  late String _userBio;
  late String _location;
  late String _nativeLanguage;
  late String _learningLevel;
  late String _learningGoal;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeProfileData();
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // First load from SharedPreferences
    final savedData = {
      'userName': prefs.getString('user_name'),
      'userBio': prefs.getString('user_bio'),
      'location': prefs.getString('location'),
      'nativeLanguage': prefs.getString('native_language'),
      'learningLevel': prefs.getString('learning_level'),
      'learningGoal': prefs.getString('learning_goal'),
      'profileImage': prefs.getString('profile_image_path'),
      'interests': prefs.getString('interests'),
    };

    // Initialize profile data from widget
    _profileData = Map<String, dynamic>.from(widget.initialData);

    if (mounted) {
      setState(() {
        // Initialize all required fields with fallbacks
        _userName = savedData['userName'] ?? _profileData['userName'] ?? '';
        _userBio = savedData['userBio'] ??
            _profileData['userBio'] ??
            'Language enthusiast';
        _location = savedData['location'] ?? _profileData['location'] ?? '';
        _nativeLanguage = savedData['nativeLanguage'] ??
            _profileData['nativeLanguage'] ??
            'English';
        _learningLevel = savedData['learningLevel'] ??
            _profileData['learningLevel'] ??
            'Beginner';
        _learningGoal = savedData['learningGoal'] ??
            _profileData['learningGoal'] ??
            'Become fluent';
        _interests = List<String>.from(
            _profileData['interests'] ?? ['Language', 'Culture']);

        // Update profile data map to ensure consistency
        _profileData.addAll({
          'userName': _userName,
          'userBio': _userBio,
          'location': _location,
          'nativeLanguage': _nativeLanguage,
          'learningLevel': _learningLevel,
          'learningGoal': _learningGoal,
          'interests': _interests,
        });
      });
    }

    await _loadScores();
    await _loadProfileImage();
  }

  void _setupPeriodicRefresh() {
    // Refresh data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadScores();
        _loadSavedProfile();
      }
    });
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('user_name') ?? _userName;
      _userBio = prefs.getString('user_bio') ?? _userBio;
      _location = prefs.getString('location') ?? _location;
      _nativeLanguage = prefs.getString('native_language') ?? _nativeLanguage;
      _learningGoal = prefs.getString('learning_goal') ?? _learningGoal;
      _learningLevel = prefs.getString('learning_level') ?? _learningLevel;
      _profileImagePath = prefs.getString('profile_image_path');

      try {
        _interests = List<String>.from(
            jsonDecode(prefs.getString('interests') ?? jsonEncode(_interests)));
      } catch (e) {
        // Keep existing interests if there's an error
        debugPrint('Error loading interests: $e');
      }

      // Update profile data map
      _profileData.addAll({
        'userName': _userName,
        'userBio': _userBio,
        'location': _location,
        'nativeLanguage': _nativeLanguage,
        'learningGoal': _learningGoal,
        'learningLevel': _learningLevel,
        'interests': _interests,
        'profileImage': _profileImagePath,
      });
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _initializeProfileData();
    }
  }

  Future<void> _loadScores() async {
    if (!mounted) return;

    try {
      final total = await ScoreService.getTotalScore();
      final games = await ScoreService.getGameScore();
      final practice = await ScoreService.getPracticeScore();

      if (mounted) {
        setState(() {
          _totalScore = total;
          _gamesScore = games;
          _practiceScore = practice;
        });
      }
    } catch (e) {
      debugPrint('Error loading scores: $e');
    }
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

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: ProfileEditForm(
          initialData: {
            'userName': _userName,
            'userBio': _userBio,
            'location': _location,
            'nativeLanguage': _nativeLanguage,
            'learningGoal': _learningGoal,
          },
          onSave: (updatedData) async {
            // Update local state
            setState(() {
              _userName = updatedData['userName']!;
              _userBio = updatedData['userBio']!;
              _location = updatedData['location']!;
              _nativeLanguage = updatedData['nativeLanguage']!;
              _learningGoal = updatedData['learningGoal']!;
            });

            // Update profile data
            _profileData.addAll(updatedData);

            // Notify parent
            widget.onUpdateProfile(_profileData);

            // Save to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', updatedData['userName']!);
            await prefs.setString('user_bio', updatedData['userBio']!);
            await prefs.setString('location', updatedData['location']!);
            await prefs.setString(
                'native_language', updatedData['nativeLanguage']!);
            await prefs.setString(
                'learning_goal', updatedData['learningGoal']!);

            // Show success message
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Color(0xFFFF5A1A),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Save all profile data including image path
    await prefs.setString('user_name', _userName);
    await prefs.setString('user_bio', _userBio);
    await prefs.setString('location', _location);
    await prefs.setString('native_language', _nativeLanguage);
    await prefs.setString('learning_goal', _learningGoal);
    if (_profileImagePath != null) {
      await prefs.setString('profile_image_path', _profileImagePath!);
    }
    await prefs.setString('interests', jsonEncode(_interests));

    // Update the profile data map
    _profileData.addAll({
      'userName': _userName,
      'userBio': _userBio,
      'location': _location,
      'nativeLanguage': _nativeLanguage,
      'learningGoal': _learningGoal,
      'profileImage': _profileImagePath,
    });

    // Notify parent of updates
    widget.onUpdateProfile(_profileData);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImagePath = pickedFile.path;
      });

      // Save image path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', pickedFile.path);

      // Update profile data
      _profileData['profileImage'] = pickedFile.path;
      widget.onUpdateProfile(_profileData);
    }
  }

  // Helper methods
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF141414),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildLanguagePreferences() {
    return Column(
      children: [
        for (String language in _profileData['preferredLanguages'])
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(language),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _profileData['proficiencyLevels'][language],
                    items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((level) =>
                            DropdownMenuItem(value: level, child: Text(level)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _profileData['proficiencyLevels'][language] = value;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _profileData['preferredLanguages'].remove(language);
                        _profileData['proficiencyLevels'].remove(language);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _showAddLanguageDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Language'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1A),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showAddLanguageDialog() {
    String? selectedLanguage;
    String? selectedLevel;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: _buildInputDecoration('Language'),
              items: [
                'Spanish',
                'French',
                'German',
                'Italian',
                'Japanese',
                'Korean'
              ]
                  .map((lang) =>
                      DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) => selectedLanguage = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: _buildInputDecoration('Level'),
              items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                  .map((level) =>
                      DropdownMenuItem(value: level, child: Text(level)))
                  .toList(),
              onChanged: (value) => selectedLevel = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedLanguage != null && selectedLevel != null) {
                setState(() {
                  _profileData['preferredLanguages'].add(selectedLanguage!);
                  _profileData['proficiencyLevels'][selectedLanguage!] =
                      selectedLevel!;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (mounted && imagePath != null) {
      setState(() {
        _profileImagePath = imagePath;
        _imageFile = File(imagePath);
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
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
                  Text(
                    _userName.isEmpty ? 'Welcome!' : _userName,
                    style: const TextStyle(
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
              child: Form(
                key: _formKey,
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
                    _buildLeaderboardSection(),
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
                      onTap: _showEditProfileDialog,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildLeaderboardSection() {
    final List<Map<String, dynamic>> leaderboardData = [
      {
        'name': 'Sarah Chen',
        'score': _totalScore + 250,
        'level': 'Expert',
        'languages': ['Mandarin', 'English', 'Spanish'],
        'streak': 45,
      },
      {
        'name': _userName,
        'score': _totalScore,
        'level': _getLevelName(_calculateLevel()),
        'languages': _profileData['preferredLanguages'],
        'streak': 14,
      },
      {
        'name': 'Miguel Rodriguez',
        'score': _totalScore - 150,
        'level': 'Advanced',
        'languages': ['Spanish', 'English', 'Portuguese'],
        'streak': 30,
      },
    ]..sort((a, b) => b['score'].compareTo(a['score']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF141414),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leaderboardData.length,
          itemBuilder: (context, index) {
            final user = leaderboardData[index];
            final isCurrentUser = user['name'] == _userName;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFFFF5A1A).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrentUser
                      ? const Color(0xFFFF5A1A)
                      : Colors.grey.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getLeaderboardColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  user['name'],
                  style: TextStyle(
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xFF141414),
                  ),
                ),
                subtitle: Text(
                  '${user['level']} • ${user['streak']} day streak',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user['score'].toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF5A1A),
                      ),
                    ),
                    Text(
                      'points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getLeaderboardColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : const AssetImage('assets/boy.jpg') as ImageProvider,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isEmpty ? 'Welcome!' : _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userBio,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem('Total', _totalScore),
              _buildScoreItem('Games', _gamesScore),
              _buildScoreItem('Practice', _practiceScore),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(Icons.info_outline, 'Bio', _userBio),
          const Divider(),
          _buildInfoItem(Icons.location_on_outlined, 'Location', _location),
          const Divider(),
          _buildInfoItem(Icons.language, 'Native Language', _nativeLanguage),
          const Divider(),
          _buildInfoItem(Icons.flag_outlined, 'Learning Goal', _learningGoal),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value),
    );
  }

  void _showNameInputDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your name to get started:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                final name = nameController.text.trim();

                await prefs.setString('user_name', name);
                if (mounted) {
                  setState(() {
                    _userName = name;
                    _profileData['userName'] = name;
                  });
                  widget.onUpdateProfile(_profileData);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score) {
    return Column(
      children: [
        Text(
          score.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Add this new widget for the edit form
class ProfileEditForm extends StatefulWidget {
  final Map<String, String> initialData;
  final Function(Map<String, String>) onSave;

  const ProfileEditForm({
    Key? key,
    required this.initialData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _nativeLanguageController;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialData['userName']);
    _bioController = TextEditingController(text: widget.initialData['userBio']);
    _locationController =
        TextEditingController(text: widget.initialData['location']);
    _nativeLanguageController =
        TextEditingController(text: widget.initialData['nativeLanguage']);
    _goalController =
        TextEditingController(text: widget.initialData['learningGoal']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _nativeLanguageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nativeLanguageController,
                  label: 'Native Language',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _goalController,
                  label: 'Learning Goal',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onSave({
                        'userName': _nameController.text,
                        'userBio': _bioController.text,
                        'location': _locationController.text,
                        'nativeLanguage': _nativeLanguageController.text,
                        'learningGoal': _goalController.text,
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }
}
