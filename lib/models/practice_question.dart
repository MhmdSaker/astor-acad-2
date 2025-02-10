class PracticeQuestion {
  final String question;
  final List<String> options;
  final int correct;
  final String? audioUrl;  // For listening practice
  final String level;
  final String? word;      // For vocabulary
  final String? meaning;   // For vocabulary
  final String? sentence;  // For grammar

  PracticeQuestion({
    required this.question,
    required this.options,
    required this.correct,
    this.audioUrl,
    required this.level,
    this.word,
    this.meaning,
    this.sentence,
  });
} 