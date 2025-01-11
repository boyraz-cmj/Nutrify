import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../../core/theme/app_colors.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

final _logger = Logger('LoginScreen');

// Firebase auth provider
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);

    // Login işlemi
    Future<void> handleLogin() async {
      if (formKey.currentState?.validate() ?? false) {
        try {
          isLoading.value = true;
          _logger.info('Login attempt for email: ${emailController.text}');

          final auth = ref.read(authProvider);
          final userCredential = await auth.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          _logger
              .info('Login successful for user: ${userCredential.user?.uid}');

          if (context.mounted) {
            _logger.info('Navigating to HomeScreen');
            await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
              (route) => false, // Tüm route stack'i temizle
            );
          }
        } on FirebaseAuthException catch (e) {
          _logger.warning('Firebase Auth Error: ${e.code} - ${e.message}');
          if (context.mounted) {
            String errorMessage;
            switch (e.code) {
              case 'user-not-found':
                errorMessage =
                    'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
                break;
              case 'wrong-password':
                errorMessage = 'Hatalı şifre girdiniz.';
                break;
              case 'invalid-email':
                errorMessage = 'Geçersiz e-posta formatı.';
                break;
              case 'user-disabled':
                errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
                break;
              default:
                errorMessage = 'Giriş yapılırken bir hata oluştu: ${e.code}';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          _logger.severe('Unexpected error during login: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Beklenmeyen bir hata oluştu: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } finally {
          isLoading.value = false;
        }
      }
    }

    // Auth state listener'ı güncelleyelim
    useEffect(() {
      final subscription = FirebaseAuth.instance.authStateChanges().listen(
        (User? user) {
          _logger.info('Auth state changed. User: ${user?.uid}');
          if (user != null && context.mounted) {
            _logger.info('User is logged in, navigating to HomeScreen');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
              (route) => false,
            );
          }
        },
        onError: (error) {
          _logger.severe('Auth state stream error: $error');
        },
      );

      return subscription.cancel;
    }, const []);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGreen.withOpacity(0.1),
              AppColors.backgroundGreen,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo ve başlık
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 60,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nutrify',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.primaryOrange,
                          ],
                        ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Input alanları
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          enabled: !isLoading.value,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppColors.primaryOrange,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen e-posta adresinizi girin';
                            }
                            if (!value.contains('@')) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          enabled: !isLoading.value,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryOrange,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          obscureText: !isPasswordVisible.value,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => handleLogin(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen şifrenizi girin';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Giriş yap butonu
                  ElevatedButton(
                    onPressed: isLoading.value ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                    child: Text(
                      'Hesabınız yok mu? Kayıt olun',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
