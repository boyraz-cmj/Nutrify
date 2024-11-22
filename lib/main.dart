import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final _logger = Logger('IngrediApp');

// Uygulama renkleri için sabitler
class AppColors {
  static const primaryGreen = Color(0xFF4CAF50); // Ana yeşil renk
  static const secondaryOrange = Color(0xFFFF9800); // İkincil turuncu renk
  static const lightGreen = Color(0xFF81C784); // Açık yeşil
  static const backgroundGreen = Color(0xFFF5F9F5); // Açık yeşil arkaplan
  static const textDark = Color(0xFF2C3E2D); // Koyu yeşil metin
  static const errorRed = Color(0xFFE57373); // Yumuşak hata kırmızısı
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.info('Firebase initialized successfully');
  } catch (e) {
    _logger.severe('Firebase initialization failed: $e');
  }

  _setupLogging();
  runApp(const ProviderScope(child: MyApp()));
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    _logger.info('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IngrediApp',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.secondaryOrange,
          tertiary: AppColors.lightGreen,
          background: AppColors.backgroundGreen,
          error: AppColors.errorRed,
        ),
        scaffoldBackgroundColor: AppColors.backgroundGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryOrange,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          prefixIconColor: AppColors.secondaryOrange,
          suffixIconColor: AppColors.secondaryOrange,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.secondaryOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.errorRed),
          ),
          labelStyle: TextStyle(color: AppColors.textDark.withOpacity(0.8)),
          floatingLabelStyle: const TextStyle(color: AppColors.secondaryOrange),
          hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: AppColors.textDark),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.primaryGreen,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.secondaryOrange,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondaryOrange,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
