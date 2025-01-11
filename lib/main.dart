import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/product_service.dart';
import 'screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_colors.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

final _logger = Logger('IngrediApp');

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.info('Firebase başarıyla başlatıldı');

    // Bağlantıyı test et
    final productService = ProductService();
    await productService.testFirebaseConnection();
  } catch (e) {
    _logger.severe('Firebase başlatma hatası: $e');
  }

  // Logging ayarları
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  await AwesomeNotifications().initialize(
    null, // null = varsayılan app icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Basic notification channel',
        defaultColor: AppColors.primaryGreen,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
    debug: true,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'IngrediApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryOrange,
          background: AppColors.backgroundGreen,
          surface: AppColors.surfaceColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.backgroundGreen,
        useMaterial3: true,
        // Card teması - gölgeler daha belirgin
        cardTheme: CardTheme(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: AppColors.surfaceColor,
          shadowColor: AppColors.neonGreenShadow
              .withOpacity(AppColors.cardShadowOpacity),
        ),
        // Buton teması - neon efektler artırıldı
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 8,
            shadowColor: AppColors.neonGreenShadow
                .withOpacity(AppColors.buttonShadowOpacity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        // Input teması - kontrast artırıldı
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceColor,
          prefixIconColor: AppColors.primaryOrange,
          suffixIconColor: AppColors.primaryOrange,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primaryGreen.withOpacity(0.5),
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primaryGreen.withOpacity(0.4),
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.accentGreen,
              width: 2.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: AppColors.textDark.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        // AppBar teması - daha belirgin
        appBarTheme: AppBarTheme(
          elevation: 4,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textLight,
          centerTitle: true,
          shadowColor: AppColors.neonGreenShadow
              .withOpacity(AppColors.neonShadowOpacity),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        // Floating Action Button teması - neon efektler güçlendirildi
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.textLight,
          elevation: 8,
          splashColor: AppColors.neonOrangeShadow.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
            backgroundColor: AppColors.neonGreenShadow,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Bir hata oluştu: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
