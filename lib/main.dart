import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme.dart';
import 'screens/splash_screen.dart';
import 'services/progress_service.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  final progressService = ProgressService();
  await progressService.init();

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<ProgressService>.value(
            value: progressService),
      ],
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      theme: ThemeData(
        fontFamily: 'CraftworkGrotesk',
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontVariations: [FontVariation('wght', 700.0)],
            fontSize: 32,
          ),
          headlineLarge: const TextStyle(
            fontVariations: [FontVariation('wght', 600.0)],
            fontSize: 28,
          ),
          titleLarge: const TextStyle(
            fontVariations: [FontVariation('wght', 500.0)],
            fontSize: 22,
          ),
          bodyLarge: const TextStyle(
            fontVariations: [FontVariation('wght', 400.0)],
            fontSize: 16,
          ),
          labelLarge: const TextStyle(
            fontVariations: [FontVariation('wght', 500.0)],
            fontSize: 14,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
