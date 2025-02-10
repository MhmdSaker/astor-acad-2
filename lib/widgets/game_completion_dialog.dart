import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';

class GameCompletionDialog extends StatefulWidget {
  final String title;
  final String message;
  final int score;
  final bool success;
  final VoidCallback onPlayAgain;

  const GameCompletionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.score,
    required this.success,
    required this.onPlayAgain,
  });

  @override
  State<GameCompletionDialog> createState() => _GameCompletionDialogState();
}

class _GameCompletionDialogState extends State<GameCompletionDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    if (widget.success) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: widget.success
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : const Color(0xFFFF5A1A).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation
                SizedBox(
                  height: 120,
                  child: Lottie.asset(
                    widget.success
                        ? 'assets/animations/success.json'
                        : 'assets/animations/game-over.json',
                    repeat: widget.success,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'CraftworkGrotesk',
                    color: widget.success
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF5A1A),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontFamily: 'CraftworkGrotesk',
                    color: Color(0xFF1C1C1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF5A1A).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFF5A1A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${widget.score}',
                        style: const TextStyle(
                          fontFamily: 'CraftworkGrotesk',
                          color: Color(0xFF1C1C1E),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7F0EB),
                        foregroundColor: const Color(0xFF1C1C1E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home),
                          SizedBox(width: 8),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: widget.onPlayAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.success
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2F6FED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Play Again',
                            style: TextStyle(
                              fontFamily: 'CraftworkGrotesk',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.success)
          Positioned(
            top: -50,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14159 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
      ],
    );
  }
}
