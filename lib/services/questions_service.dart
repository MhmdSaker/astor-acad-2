import '../models/practice_question.dart';

class QuestionsService {
  static List<PracticeQuestion> getVocabularyQuestions(String level) {
    switch (level) {
      case 'Beginner':
        return [
          PracticeQuestion(
            question: 'What is the meaning of "Hello"?',
            options: ['Goodbye', 'Thank you', 'Hi', 'Please'],
            correct: 2,
            level: 'Beginner',
          ),
          // Add more beginner questions...
        ];
      case 'Intermediate':
        return [
          PracticeQuestion(
            question: 'What is the meaning of "Procrastinate"?',
            options: [
              'To delay',
              'To hurry',
              'To finish',
              'To start',
            ],
            correct: 0,
            level: 'Intermediate',
          ),
          // Add more intermediate questions...
        ];
      case 'Advanced':
        return [
          PracticeQuestion(
            question: 'What is the meaning of "Ephemeral"?',
            options: [
              'Lasting forever',
              'Short-lived',
              'Important',
              'Meaningful',
            ],
            correct: 1,
            level: 'Advanced',
          ),
          // Add more advanced questions...
        ];
      default:
        return [];
    }
  }

  static List<PracticeQuestion> getGrammarQuestions(String level) {
    switch (level) {
      case 'Beginner':
        return [
          PracticeQuestion(
            question: 'Choose the correct form: "I ___ a student."',
            options: ['am', 'is', 'are', 'be'],
            correct: 0,
            level: 'Beginner',
          ),
          // Add more beginner questions...
        ];
      case 'Intermediate':
        return [
          PracticeQuestion(
            question: 'Select the correct conditional: "If I ___ rich, I ___ travel the world."',
            options: [
              'am / will',
              'were / would',
              'was / would',
              'am / would',
            ],
            correct: 1,
            level: 'Intermediate',
          ),
          // Add more intermediate questions...
        ];
      case 'Advanced':
        return [
          PracticeQuestion(
            question: 'Choose the correct subjunctive: "I suggest that he ___ the matter."',
            options: [
              'study',
              'studies',
              'studied',
              'has studied',
            ],
            correct: 0,
            level: 'Advanced',
          ),
          // Add more advanced questions...
        ];
      default:
        return [];
    }
  }

  static List<PracticeQuestion> getListeningQuestions(String level) {
    switch (level) {
      case 'Beginner':
        return [
          PracticeQuestion(
            question: 'Listen and select what you hear:',
            options: ['Hello', 'Goodbye', 'Thank you', 'Please'],
            correct: 0,
            audioUrl: 'assets/audio/beginner/hello.mp3',
            level: 'Beginner',
          ),
          // Add more beginner questions...
        ];
      case 'Intermediate':
        return [
          PracticeQuestion(
            question: 'Listen to the conversation and answer:',
            options: [
              'They are discussing weather',
              'They are making plans',
              'They are ordering food',
              'They are studying',
            ],
            correct: 1,
            audioUrl: 'assets/audio/intermediate/conversation1.mp3',
            level: 'Intermediate',
          ),
          // Add more intermediate questions...
        ];
      case 'Advanced':
        return [
          PracticeQuestion(
            question: 'Listen to the lecture and identify the main topic:',
            options: [
              'Climate change',
              'Economic policy',
              'Social media',
              'Technology',
            ],
            correct: 0,
            audioUrl: 'assets/audio/advanced/lecture1.mp3',
            level: 'Advanced',
          ),
          // Add more advanced questions...
        ];
      default:
        return [];
    }
  }
} 