import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../home_screen.dart';

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
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                enabled: !isLoading.value,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
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
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: !isLoading.value
                        ? () {
                            isPasswordVisible.value = !isPasswordVisible.value;
                          }
                        : null,
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading.value ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
