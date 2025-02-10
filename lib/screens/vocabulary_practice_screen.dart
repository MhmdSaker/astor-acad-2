import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../widgets/progress_display.dart';
import 'package:provider/provider.dart';
import '../widgets/results_dialog.dart';
import '../widgets/practice_results_dialog.dart';
import '../data/vocabulary_questions.dart';
import '../models/practice_question.dart';

class VocabularyPracticeScreen extends StatefulWidget {
  final String level;

  const VocabularyPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<VocabularyPracticeScreen> createState() =>
      _VocabularyPracticeScreenState();
}

class _VocabularyPracticeScreenState extends State<VocabularyPracticeScreen>
    with SingleTickerProviderStateMixin {
  // Update color palette to match games screen
  static const Color primaryColor =
      Color(0xFFFF5A1A); // Orange from games screen
  static const Color secondaryColor =
      Color(0xFF2F6FED); // Blue from games screen
  static const Color accentColor = Color(0xFF4CAF50); // Green from games screen
  static const Color backgroundColor = Color(0xFFF7F0EB); // Light background
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1C1C1E);

  int currentWord = 0;
  bool isAnswered = false;
  int selectedAnswer = -1;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  bool isAnimating = false;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  bool isQuizFinished = false;
  late final String category = 'vocabulary';
  int currentPoints = 0;
  static const int basePointsPerQuestion = 10;
  double progressAnimation = 0.0;
  double masteryAnimation = 0.0;
  int totalQuestions = 10;
  late DateTime _startTime;
  late DateTime _questionStartTime;
  late List<PracticeQuestion> questions;

  final progressService = ProgressService();

  @override
  void initState() {
    super.initState();
    questions = VocabularyQuestions.questions[widget.level] ?? [];
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _startTime = DateTime.now();
    _questionStartTime = DateTime.now();
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
                                    'Correct meaning: ${questions[currentWord].meaning ?? 'No meaning provided'}',
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

  Widget _buildProgressHeader() {
    return AnimatedBuilder(
      animation: progressService,
      builder: (context, child) {
        final stats = progressService.getCategoryStats(category);
        final progress = progressService.getCategoryProgress(category);

        // Calculate accuracy safely
        final totalAttempts = correctAnswers + wrongAnswers;
        final accuracy = totalAttempts > 0
            ? ((correctAnswers / totalAttempts) * 100).round()
            : 0;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          tween:
              Tween(begin: masteryAnimation, end: stats['mastery'] as double),
          builder: (context, mastery, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Level ${stats['level']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}% to next',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween(begin: 0, end: stats['mastery'] as double),
                        builder: (context, value, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  value: value,
                                  backgroundColor: const Color(0xFF2C2C2E),
                                  valueColor: AlwaysStoppedAnimation(
                                    _getProgressColor(value),
                                  ),
                                  strokeWidth: 6,
                                ),
                              ),
                              Text(
                                '${(value * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Score',
                        '$correctAnswers/${questions.length}',
                        Icons.check_circle_outline,
                        const Color(0xFF4CAF50),
                      ),
                      _buildStatItem(
                        'Points',
                        currentPoints.toString(),
                        Icons.stars,
                        const Color(0xFFFFA726),
                      ),
                      _buildStatItem(
                        'Accuracy',
                        '$accuracy%',
                        Icons.analytics,
                        const Color(0xFF2F6FED),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getProgressColor(double mastery) {
    if (mastery >= 0.9) return const Color(0xFF4CAF50);
    if (mastery >= 0.7) return const Color(0xFF2F6FED);
    if (mastery >= 0.5) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }

  int _calculateTimeBonus(Duration timeSpent) {
    // Base points for answering correctly
    const int basePoints = 10;
    // Maximum time bonus possible
    const int maxTimeBonus = 5;
    // Time threshold in seconds (faster = more bonus)
    const int timeThreshold = 10;

    // Calculate bonus based on response time
    final seconds = timeSpent.inSeconds;
    if (seconds <= timeThreshold) {
      // More bonus for faster responses
      final bonus =
          ((timeThreshold - seconds) / timeThreshold * maxTimeBonus).round();
      return basePoints + bonus;
    }

    // Just base points if took longer than threshold
    return basePoints;
  }

  void _checkAnswer(int index) {
    if (isAnswered) return;

    final timeSpent = DateTime.now().difference(_questionStartTime);
    final correctIndex = questions[currentWord].correct;

    setState(() {
      isAnswered = true;
      selectedAnswer = index;

      if (index == correctIndex) {
        correctAnswers++;
        final points = _calculateTimeBonus(timeSpent);
        currentPoints += points;

        // Update progress immediately
        Provider.of<ProgressService>(context, listen: false)
            .updateCategoryProgress(
          category: category,
          correctAnswers: correctAnswers,
          totalQuestions: questions.length,
          points: points,
          timeSpent: DateTime.now().difference(_startTime),
        );

        progressAnimation = (currentWord + 1) / questions.length;
        masteryAnimation = correctAnswers / questions.length;

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
          if (currentWord < questions.length - 1) {
            currentWord++;
            isAnswered = false;
            selectedAnswer = -1;
            _questionStartTime =
                DateTime.now(); // Reset timer for next question
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
    final percentage = (correctAnswers / questions.length * 100).round();

    // Update this line - use currentPoints instead of calculating from percentage
    final points =
        currentPoints; // This already contains the base 10 + any time bonuses

    // Final update to progress
    Provider.of<ProgressService>(context, listen: false).updateCategoryProgress(
      category: category,
      correctAnswers: correctAnswers,
      totalQuestions: questions.length,
      points: points,
      timeSpent: timeSpent,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PracticeResultsDialog(
        correctAnswers: correctAnswers,
        totalQuestions: questions.length,
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
                    color: const Color(0xFF4CAF50),
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

  Widget _buildAnimatedButton(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 1.0, end: isAnswered ? 0.95 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getButtonColor(index).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _checkAnswer(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(index),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isAnswered ? 2 : 5,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      questions[currentWord].options[index],
                      style: TextStyle(
                        color: textColor.withOpacity(isAnswered ? 0.9 : 1),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateProgress(BuildContext context) {
    final progressService =
        Provider.of<ProgressService>(context, listen: false);
    final points = progressService.calculatePoints(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      streak: progressService.currentStreak,
    );

    progressService.updateCategoryProgress(
      category: category,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      points: points,
      timeSpent: DateTime.now().difference(_startTime),
    );
  }

  Color _getButtonColor(int index) {
    if (!isAnswered) {
      return primaryColor;
    }

    final correctIndex = questions[currentWord].correct;
    if (index == correctIndex) {
      return accentColor;
    }
    if (index == selectedAnswer && selectedAnswer != correctIndex) {
      return Colors.red;
    }
    return primaryColor.withOpacity(0.5);
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
                            'Vocabulary Practice',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Word ${currentWord + 1} of ${questions.length}',
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
                            '${((currentWord + 1) / questions.length * 100).toInt()}%',
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
                          value: (currentWord + 1) / questions.length,
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
                      Text(
                        questions[currentWord].word ?? 'Word',
                        style: TextStyle(
                          fontFamily: 'CraftworkGrotesk',
                          color: textColor,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Choose the correct meaning',
                          style: TextStyle(
                            fontFamily: 'CraftworkGrotesk',
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(
                    questions[currentWord].options.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getButtonColor(index).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getButtonColor(index).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _checkAnswer(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:
                                        _getButtonColor(index).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        fontFamily: 'CraftworkGrotesk',
                                        color: _getButtonColor(index),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    questions[currentWord].options[index],
                                    style: TextStyle(
                                      fontFamily: 'CraftworkGrotesk',
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // When practice is complete
  void _onPracticeComplete() {
    Navigator.pop(context); // Return to practice screen
    if (mounted) {
      Provider.of<ProgressService>(context, listen: false)
          .updateCategoryProgress(
        category: 'vocabulary',
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        points: currentPoints,
        timeSpent: DateTime.now().difference(_startTime),
      );
    }
  }
}
