import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const String _gameScoreKey = 'game_score';
  static const String _practiceScoreKey = 'practice_score';
  static const String _totalScoreKey = 'total_score';

  // Get game score
  static Future<int> getGameScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gameScoreKey) ?? 0;
  }

  // Get practice score
  static Future<int> getPracticeScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_practiceScoreKey) ?? 0;
  }

  // Get total score
  static Future<int> getTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    final gameScore = prefs.getInt(_gameScoreKey) ?? 0;
    final practiceScore = prefs.getInt(_practiceScoreKey) ?? 0;
    final total = gameScore + practiceScore;
    await prefs.setInt(_totalScoreKey, total);
    return total;
  }

  // Update game score
  static Future<void> updateGameScore(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final currentScore = await getGameScore();
    await prefs.setInt(_gameScoreKey, currentScore + points);
  }

  // Update practice score
  static Future<void> updatePracticeScore(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final currentScore = await getPracticeScore();
    await prefs.setInt(_practiceScoreKey, currentScore + points);
  }
} 