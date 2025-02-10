import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/speech_service.dart';
import '../services/progress_service.dart';
import 'package:provider/provider.dart';
import '../widgets/practice_results_dialog.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';
import '../services/pronunciation_service.dart';

class PronunciationPracticeScreen extends StatefulWidget {
  final String level;
  const PronunciationPracticeScreen({super.key, required this.level});

  @override
  State<PronunciationPracticeScreen> createState() =>
      _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState
    extends State<PronunciationPracticeScreen> {
  late VideoPlayerController _controller;
  late SpeechService _speechService;
  bool isVideoPlaying = false;
  bool isListening = false;
  String originalText = "";
  String spokenText = "";
  bool isReady = false;
  late DateTime _startTime;
  int currentPoints = 0;
  String category = 'pronunciation';

  // Updated movie scene data to match numbered video files
  final List<Map<String, dynamic>> movieScenes = [
    {
      'videoUrl': 'assets/scenes/1.mp4',
      'subtitle':
          "If you only remember one thing, it's distract the zombies until I get close enough to put a wooshy finger hold on Kai",
      'movie': 'Scene 1',
      'difficulty': 'Intermediate',
      'timestamp': '1:23',
    },
    {
      'videoUrl': 'assets/scenes/2.mp4',
      'subtitle':
          "Getting into trouble a little early today, aren't we, Aladdin?",
      'movie': 'Scene 2',
      'difficulty': 'Beginner',
      'timestamp': '2:15',
    },
    {
      'videoUrl': 'assets/scenes/3.mp4',
      'subtitle':
          "Okay, so, Mother, as I was saying, tomorrow is... Rapunzel, Mother's feeling a little run down.",
      'movie': 'Scene 3',
      'difficulty': 'Intermediate',
      'timestamp': '1:45',
    },
    {
      'videoUrl': 'assets/scenes/4.mp4',
      'subtitle':
          "Moana of Motunui, I believe you have officially delivered Maui across the great sea",
      'movie': 'Scene 4',
      'difficulty': 'Intermediate',
      'timestamp': '0:58',
    },
    {
      'videoUrl': 'assets/scenes/5.mp4',
      'subtitle':
          "Seriously now, I'd love to have a little togue with you, Linguini, in my office",
      'movie': 'Scene 5',
      'difficulty': 'Beginner',
      'timestamp': '1:34',
    },
    {
      'videoUrl': 'assets/scenes/6.mp4',
      'subtitle': "Anyone can be anything, that's what makes Zootopia great!",
      'movie': 'Scene 6',
      'difficulty': 'Beginner',
      'timestamp': '0:45',
    },
  ];

  // Colors matching the app theme
  static const Color primaryColor = Color(0xFFFF5A1A);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF7F0EB);
  static const Color textColor = Color(0xFF1C1C1E);

  // Add new properties
  int currentSceneIndex = 0;
  bool canReplay = true;

  // Add new properties for speech handling
  bool _isProcessing = false;
  Timer? _silenceTimer;
  String _currentSpeech = '';
  bool _isSpeaking = false;

  // Add these properties to track overall statistics
  List<Map<String, dynamic>> sessionStats = [];

  final PronunciationService _pronunciationService = PronunciationService();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    currentSceneIndex = 0; // Explicitly start with first scene
    _initializeVideo();
    _speechService = SpeechService();
  }

  Future<void> _initializeVideo() async {
    try {
      // Instead of using firstWhere, use currentSceneIndex
      final scene = movieScenes[currentSceneIndex];
      print('Initializing video: ${scene['videoUrl']}'); // Debug print

      _controller = VideoPlayerController.asset(scene['videoUrl']);
      await _controller.initialize();

      if (mounted) {
        setState(() {
          originalText = scene['subtitle'];
          isReady = true;
          canReplay = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startListening() async {
    setState(() {
      isListening = true;
      _currentSpeech = '';
    });

    // Add timeout to automatically stop listening if no speech is detected
    Timer(const Duration(seconds: 10), () {
      if (mounted && isListening && _currentSpeech.isEmpty) {
        _pronunciationService.stop();
        _analyzePronunciation();
      }
    });

    try {
      await _pronunciationService.startListening(
        onTextRecognized: (text) {
          print('Recognized text: $text');
          setState(() {
            _currentSpeech = text;
            spokenText = text;
          });
          _resetSilenceTimer();
        },
        onSilence: () {
          print('Silence detected');
          _startSilenceTimer();
        },
        silenceThreshold: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _handleSpeechError(e.toString());
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      if (_currentSpeech.isNotEmpty) {
        _analyzePronunciation();
      }
    });
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      if (_currentSpeech.isNotEmpty) {
        _analyzePronunciation();
      }
    });
  }

  void _analyzePronunciation() {
    if (_isProcessing) return;
    _isProcessing = true;

    if (_currentSpeech.isEmpty) {
      // Show alert for no speech input
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: backgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: primaryColor),
              const SizedBox(width: 12),
              Text(
                'No Speech Detected',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Please speak the line clearly when the microphone is listening.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset state and try again
                setState(() {
                  isListening = false;
                  _isProcessing = false;
                  canReplay = true;
                });
              },
              child: Text(
                'Try Again',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final double similarity = originalText.similarityTo(_currentSpeech);
    final int accuracyPercentage = (similarity * 100).round();
    final points = _calculatePoints(accuracyPercentage);

    // Stop listening before showing results
    _pronunciationService.stop();

    setState(() {
      isListening = false;
      spokenText = _currentSpeech;
    });

    _showResults(accuracyPercentage, points);
    _isProcessing = false;
  }

  int _calculatePoints(int accuracy) {
    const basePoints = 10;
    final bonus = (accuracy / 100 * 20).round(); // Up to 20 bonus points
    return basePoints + bonus;
  }

  void _showResults(int accuracy, int points) {
    final timeSpent = DateTime.now().difference(_startTime);

    // Add current scene stats to session stats
    sessionStats.add({
      'scene': currentSceneIndex + 1,
      'accuracy': accuracy,
      'points': points,
      'timeSpent': timeSpent,
      'subtitle': originalText,
    });

    Provider.of<ProgressService>(context, listen: false).updateCategoryProgress(
      category: category,
      correctAnswers: 1,
      totalQuestions: 1,
      points: points,
      timeSpent: timeSpent,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accuracy > 80
                        ? accentColor.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accuracy > 80
                          ? accentColor.withOpacity(0.2)
                          : primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: _buildAccuracyMeter(accuracy),
                  ),
                ),
                if (accuracy > 80)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Original',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    originalText,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Text(
                    'Your Pronunciation',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spokenText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accuracy > 80
                    ? accentColor.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    accuracy > 80 ? Icons.emoji_events : Icons.tips_and_updates,
                    color: accuracy > 80 ? accentColor : primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _buildFeedbackText(accuracy),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Conditional button row based on accuracy
            if (accuracy < 60)
              // Show only Try Again button for low accuracy
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  setState(() {
                    canReplay = true;
                    _currentSpeech = '';
                    spokenText = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh),
                    const SizedBox(width: 8),
                    Text('Try Again'),
                  ],
                ),
              )
            else
              // Show both buttons for good accuracy
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Exit'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _loadNextScene();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Next Scene'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _buildFeedbackText(int accuracy) {
    if (accuracy > 90) {
      return 'Outstanding! Your pronunciation is nearly perfect!';
    } else if (accuracy > 80) {
      return 'Great job! Keep practicing to perfect those small details.';
    } else if (accuracy > 70) {
      return 'Good effort! Focus on matching the rhythm and intonation.';
    } else {
      return 'Keep practicing! Try to break down the sentence into smaller parts.';
    }
  }

  void _loadNextScene() async {
    // First ensure dialog is closed
    Navigator.of(context, rootNavigator: true).pop();

    // Calculate next scene index
    final nextIndex = (currentSceneIndex + 1) % movieScenes.length;

    // Check if this was the last scene
    if (nextIndex == 0) {
      _showFinalStats();
      return;
    }

    print('Loading next scene: ${movieScenes[nextIndex]['videoUrl']}');

    setState(() {
      isReady = false;
      currentSceneIndex = nextIndex;
    });

    try {
      await _controller.dispose();
      final nextScene = movieScenes[currentSceneIndex];
      _controller = VideoPlayerController.asset(nextScene['videoUrl']);
      await _controller.initialize();

      if (mounted) {
        setState(() {
          originalText = nextScene['subtitle'];
          isReady = true;
          canReplay = true;
          _currentSpeech = '';
          spokenText = '';
          _startTime = DateTime.now(); // Reset start time for new scene
        });
      }
    } catch (e) {
      print('Error loading next scene: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading next scene'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFinalStats() {
    final totalScenes = sessionStats.length;
    final avgAccuracy =
        sessionStats.map((s) => s['accuracy'] as int).reduce((a, b) => a + b) ~/
            totalScenes;
    final totalPoints =
        sessionStats.map((s) => s['points'] as int).reduce((a, b) => a + b);
    final totalTime = sessionStats
        .map((s) => (s['timeSpent'] as Duration).inSeconds)
        .reduce((a, b) => a + b);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              avgAccuracy > 80 ? Icons.emoji_events : Icons.bar_chart,
              color: avgAccuracy > 80 ? accentColor : primaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Practice Complete!',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem(
              icon: Icons.analytics,
              label: 'Average Accuracy',
              value: '$avgAccuracy%',
              color: _getAccuracyColor(avgAccuracy),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              icon: Icons.stars,
              label: 'Total Points',
              value: totalPoints.toString(),
              color: primaryColor,
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              icon: Icons.timer,
              label: 'Total Time',
              value: _formatDuration(Duration(seconds: totalTime)),
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: avgAccuracy > 80
                    ? accentColor.withOpacity(0.1)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getFinalFeedback(avgAccuracy),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pop all the way back to home screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Exit Practice',
              style: TextStyle(color: primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                currentSceneIndex = 0;
                sessionStats.clear();
                _initializeVideo();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy > 80) return accentColor;
    if (accuracy > 60) return primaryColor;
    return Colors.orange;
  }

  String _getFinalFeedback(int avgAccuracy) {
    if (avgAccuracy > 90) {
      return 'Outstanding! Your pronunciation is excellent!';
    } else if (avgAccuracy > 80) {
      return 'Great job! Keep practicing to perfect your pronunciation.';
    } else if (avgAccuracy > 70) {
      return 'Good effort! Focus on matching the rhythm and intonation.';
    } else {
      return 'Keep practicing! Try to break down the sentences into smaller parts.';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildAccuracyMeter(int accuracy) {
    return Container(
      height: 100,
      width: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: accuracy / 100,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              accuracy > 80 ? accentColor : primaryColor,
            ),
            strokeWidth: 10,
          ),
          Text(
            '$accuracy%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic,
            color: primaryColor,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Listening...',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Always show the container, but with different content based on speech
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_currentSpeech.isNotEmpty)
                Text(
                  _currentSpeech,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Speak the line clearly...',
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Time remaining: 10s',
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Keep speaking until you finish the line',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final currentScene = movieScenes[currentSceneIndex];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          'Pronunciation Practice',
          style: TextStyle(
            fontFamily: 'CraftworkGrotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'How to Practice',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpItem(
                          Icons.play_circle_outline,
                          'Watch the scene and listen carefully',
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem(
                          Icons.mic,
                          'When the microphone appears, repeat the line',
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem(
                          Icons.speed,
                          'Try to match the speed and tone of the speaker',
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem(
                          Icons.refresh,
                          'Practice until you achieve high accuracy',
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Got it',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movie info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.movie, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentScene['movie'],
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Scene at ${currentScene['timestamp']}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentScene['difficulty'],
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Video player with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                const SizedBox(height: 24),
                // Subtitle section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    originalText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // Controls section
                if (!isListening)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              canReplay
                                  ? Icons.play_arrow
                                  : Icons.hourglass_empty,
                              size: 40,
                              color: primaryColor,
                            ),
                            onPressed: canReplay
                                ? () async {
                                    setState(() => canReplay = false);
                                    await _controller.seekTo(Duration.zero);
                                    await _controller.play();
                                    Future.delayed(_controller.value.duration!,
                                        () {
                                      if (mounted) {
                                        setState(() => canReplay = true);
                                        _startListening();
                                      }
                                    });
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          canReplay ? 'Watch and Listen' : 'Playing...',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Watch the scene, then repeat the line',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!canReplay)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: LinearProgressIndicator(
                              backgroundColor: primaryColor.withOpacity(0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  _buildListeningSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _controller.dispose();
    _pronunciationService.dispose();
    super.dispose();
  }

  // Add this method to handle errors
  void _handleSpeechError(String error) {
    print('Speech Error: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
      isListening = false;
      _isProcessing = false;
    });
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
