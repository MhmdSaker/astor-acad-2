import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  String _currentLanguage = 'English';

  static const Map<String, String> languageCodes = {
    'English': 'en',
    'Spanish': 'es',
    'Italian': 'it',
    'German': 'de',
    'French': 'fr',
  };

  String get currentLanguage => _currentLanguage;
  String get currentLanguageCode => languageCodes[_currentLanguage] ?? 'en';

  void setLanguage(String language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  static String getLanguageFlag(String language) {
    switch (language) {
      case 'English':
        return 'assets/flags/unitedstates.png';
      case 'Spanish':
        return 'assets/flags/spain.png';
      case 'Italian':
        return 'assets/flags/italy.png';
      case 'German':
        return 'assets/flags/germany.png';
      case 'French':
        return 'assets/flags/france.png';
      default:
        return 'assets/flags/unitedstates.png';
    }
  }
}
