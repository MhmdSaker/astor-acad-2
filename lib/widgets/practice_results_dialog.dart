import 'package:flutter/material.dart';
import '../widgets/practice_results_dialog.dart';

class PracticeResultsDialog extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final String timeSpent;
  final int accuracy;
  final int points;
  final VoidCallback onContinue;

  const PracticeResultsDialog({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    required this.accuracy,
    required this.points,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text(
        'Practice Complete!',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem(
            'Score',
            '$correctAnswers/$totalQuestions',
            Icons.stars,
            const Color(0xFF2F6FED),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Accuracy',
            '$accuracy%',
            Icons.analytics,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Time',
            timeSpent,
            Icons.timer,
            const Color(0xFFFFA726),
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Points Earned',
            '+$points',
            Icons.emoji_events,
            const Color(0xFF9C27B0),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: const Text(
            'Continue',
            style: TextStyle(color: Color(0xFF2F6FED)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 