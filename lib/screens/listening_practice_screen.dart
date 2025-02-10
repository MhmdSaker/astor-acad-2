import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/progress_service.dart';
import '../services/eleven_labs_service.dart';
import 'package:just_audio/just_audio.dart';
import '../services/speech_service.dart';
import '../widgets/results_dialog.dart';
import 'dart:math';
import '../widgets/practice_results_dialog.dart';

class ListeningPracticeScreen extends StatefulWidget {
  final String level;
  const ListeningPracticeScreen({super.key, required this.level});

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  final TextEditingController _answerController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ProgressService progressService = ProgressService();
  bool isPlaying = false;
  bool isAnswered = false;
  int currentWordIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  double progressAnimation = 0.0;
  double masteryAnimation = 0.0;
  late final String category = 'listening';
  int currentPoints = 0;
  int pointsPerCorrectAnswer = 20;
  bool isAnimating = false;
  late DateTime _startTime;
  late DateTime _questionStartTime;

  // Update color palette to match games screen
  static const Color primaryColor =
      Color(0xFFFF5A1A); // Orange from games screen
  static const Color secondaryColor =
      Color(0xFF2F6FED); // Blue from games screen
  static const Color accentColor = Color(0xFF4CAF50); // Green from games screen
  static const Color backgroundColor =
      Color(0xFFF7F0EB); // Light background from games screen
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1C1C1E);

  final List<String> words = [
    'Elephant',
    'Beautiful',
    'Computer',
    'Adventure',
    'Chocolate',
    'Mountain',
    'Butterfly',
    'Orchestra',
    'Happiness',
    'Universe',
  ];

  late final SpeechService _speechService;
  bool isLoading = false;
  int hintsRemaining = 3;
  bool isVisualizing = false;
  List<double> audioVisualizerBars = List.generate(30, (index) => 0.0);

  // Update the constants
  static const int basePointsPerQuestion = 10; // Changed from 20

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _questionStartTime = DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );

    _speechService = SpeechService();
    _speechService.initialize();
    _loadCurrentWord();
  }

  Future<void> _loadCurrentWord() async {
    setState(() => isLoading = true);
    try {
      await _speechService.speakWithElevenLabs(words[currentWordIndex]);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _playAudio() async {
    if (_speechService.isSpeaking) {
      await _speechService.stopSpeaking();
      setState(() => isVisualizing = false);
    } else {
      setState(() => isVisualizing = true);
      _updateAudioVisualization();
      await _speechService.speakWithElevenLabs(words[currentWordIndex]);
      setState(() => isVisualizing = false);
    }
    setState(() {});
  }

  void _updateAudioVisualization() {
    if (_speechService.isSpeaking) {
      setState(() {
        audioVisualizerBars = List.generate(
          30,
          (index) =>
              (0.1 + Random().nextDouble() * 0.9) *
              (_speechService.isSpeaking ? 1.0 : 0.1),
        );
      });
      Future.delayed(
          const Duration(milliseconds: 50), _updateAudioVisualization);
    } else {
      setState(() {
        audioVisualizerBars = List.generate(30, (index) => 0.1);
      });
    }
  }

  void _showPointsGainAnimation(int points) {
    late final OverlayEntry overlay;

    overlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        right: 24,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 * value),
              child: Opacity(
                opacity: 1 - value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 16),
                      Text(
                        '$points',
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
            );
          },
          onEnd: () => overlay.remove(),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
  }

  int _calculateTimeBonus(Duration timeSpent) {
    const int basePoints = 10;
    const int maxTimeBonus = 5;
    const int timeThreshold = 10;

    final seconds = timeSpent.inSeconds;
    if (seconds <= timeThreshold) {
      final bonus =
          ((timeThreshold - seconds) / timeThreshold * maxTimeBonus).round();
      return basePoints + bonus;
    }

    return basePoints;
  }

  void _checkAnswer() {
    if (isAnswered) return;

    final timeSpent = DateTime.now().difference(_questionStartTime);
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = words[currentWordIndex].toLowerCase();

    setState(() {
      isAnswered = true;

      if (userAnswer == correctAnswer) {
        correctAnswers++;
        final points = _calculateTimeBonus(timeSpent);
        currentPoints += points;

        // Update progress immediately
        Provider.of<ProgressService>(context, listen: false)
            .updateCategoryProgress(
          category: category,
          correctAnswers: correctAnswers,
          totalQuestions: words.length,
          points: points,
          timeSpent: DateTime.now().difference(_startTime),
        );

        progressAnimation = (currentWordIndex + 1) / words.length;
        masteryAnimation = correctAnswers / words.length;

        _showPointsGainAnimation(points);
        _showFeedbackAnimation(true);
      } else {
        wrongAnswers++;
        _showFeedbackAnimation(false);
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          if (currentWordIndex < words.length - 1) {
            currentWordIndex++;
            isAnswered = false;
            _answerController.clear();
            _questionStartTime =
                DateTime.now(); // Reset timer for next question
            _loadCurrentWord();
          } else {
            _showFinalResults();
          }
        });
      }
    });
  }

  void _showFinalResults() {
    final timeSpent = DateTime.now().difference(_startTime);
    final minutes = timeSpent.inMinutes;
    final seconds = timeSpent.inSeconds % 60;
    final percentage = (correctAnswers / words.length * 100).round();

    // Use currentPoints which accumulates the 10 points + bonus per correct answer
    final points = currentPoints;

    // Final update to progress
    Provider.of<ProgressService>(context, listen: false).updateCategoryProgress(
      category: category,
      correctAnswers: correctAnswers,
      totalQuestions: words.length,
      points: points,
      timeSpent: timeSpent,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PracticeResultsDialog(
        correctAnswers: correctAnswers,
        totalQuestions: words.length,
        timeSpent: '$minutes:${seconds.toString().padLeft(2, '0')}',
        accuracy: percentage,
        points: points,
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSuccessAnimation() {
    _showFeedbackAnimation(true);
  }

  void _showErrorAnimation() {
    _showFeedbackAnimation(false);
  }

  void _showFeedbackAnimation(bool isCorrect) {
    setState(() => isAnimating = true);

    if (!isCorrect) {
      _animationController
          .forward()
          .then((_) => _animationController.reverse());
    }

    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, _, child) {
        return Stack(
          children: [
            Container(
              color: Colors.black.withOpacity(0.3 * animation.value),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                ),
                child: AlertDialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  content: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isCorrect ? accentColor : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isCorrect ? accentColor : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(
                                isCorrect
                                    ? Icons.check_circle_outline
                                    : Icons.close_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isCorrect ? 'Correct!' : 'Incorrect',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isCorrect) ...[
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 400),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Text(
                                    'Correct word: ${words[currentWordIndex]}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      barrierDismissible: false,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => isAnimating = false);
      }
    });
  }

  void _useHint() {
    if (hintsRemaining > 0) {
      setState(() {
        hintsRemaining--;
        _answerController.text = words[currentWordIndex][0];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Hint: Word starts with "${words[currentWordIndex][0]}"'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
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
                          Text(
                            'Listening Practice',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Word ${currentWordIndex + 1} of ${words.length}',
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
                              '$currentPoints',
                              style: TextStyle(
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
                          Text(
                            'Progress',
                            style: const TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${((currentWordIndex + 1) / words.length * 100).toInt()}%',
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
                          value: (currentWordIndex + 1) / words.length,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
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
                      // Audio visualizer and play button
                      if (isVisualizing) _buildAudioVisualizer(),
                      const SizedBox(height: 20),
                      _buildPlayButton(),
                      const SizedBox(height: 20),
                      Text(
                        'Listen and type what you hear',
                        style: TextStyle(
                          fontFamily: 'CraftworkGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnswerInput(),
                if (hintsRemaining > 0) _buildHintButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          30,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 4,
            height: 60 * audioVisualizerBars[index],
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        iconSize: 48,
        icon: Icon(
          _speechService.isSpeaking
              ? Icons.pause_circle
              : Icons.play_circle_fill,
          color: textColor,
        ),
        onPressed: _playAudio,
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _answerController,
        style: const TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Type what you hear...',
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
            fontSize: 16,
          ),
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: textColor),
              onPressed: _checkAnswer,
            ),
          ),
        ),
        onSubmitted: (_) => _checkAnswer(),
      ),
    );
  }

  Widget _buildHintButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton.icon(
        onPressed: _useHint,
        icon: Icon(Icons.lightbulb_outline, color: accentColor),
        label: Text(
          'Use Hint ($hintsRemaining remaining)',
          style: TextStyle(color: accentColor),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    _answerController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
