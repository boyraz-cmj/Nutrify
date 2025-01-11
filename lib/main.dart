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
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundGreen,
          prefixIconColor: AppColors.primaryOrange,
          suffixIconColor: AppColors.primaryOrange,
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
                const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
        ),
      ),
      home: authState.when(
        data: (user) {
          return user != null ? const HomeScreen() : const LoginScreen();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Bir hata oluştu: $error'),
        ),
      ),
    );
  }
}
