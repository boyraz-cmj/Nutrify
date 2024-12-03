import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../../core/theme/app_colors.dart';

final _logger = Logger('UserSettingsScreen');

class UserSettingsScreen extends HookConsumerWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmNewPasswordController = useTextEditingController();
    final isCurrentPasswordVisible = useState(false);
    final isNewPasswordVisible = useState(false);
    final isConfirmPasswordVisible = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final nameController = useTextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '',
    );

    Future<void> changePassword() async {
      if (formKey.currentState?.validate() ?? false) {
        try {
          isLoading.value = true;
          final user = FirebaseAuth.instance.currentUser;
          final email = user?.email;

          if (user == null || email == null) {
            throw Exception('Kullanıcı oturumu bulunamadı');
          }

          // Mevcut şifreyi doğrula
          final credential = EmailAuthProvider.credential(
            email: email,
            password: currentPasswordController.text,
          );

          // Kullanıcıyı yeniden kimlik doğrulamasından geçir
          await user.reauthenticateWithCredential(credential);

          // Şifreyi güncelle
          await user.updatePassword(newPasswordController.text);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Şifreniz başarıyla güncellendi'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Ayarlar sayfasını kapat
          }
        } catch (e) {
          _logger.warning('Şifre değiştirme hatası: $e');
          if (context.mounted) {
            String errorMessage = 'Şifre değiştirme işlemi başarısız oldu';
            if (e is FirebaseAuthException) {
              switch (e.code) {
                case 'wrong-password':
                  errorMessage = 'Mevcut şifreniz yanlış';
                  break;
                case 'weak-password':
                  errorMessage = 'Yeni şifre çok zayıf';
                  break;
                default:
                  errorMessage = 'Bir hata oluştu: ${e.message}';
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          isLoading.value = false;
        }
      }
    }

    Future<void> updateDisplayName() async {
      try {
        isLoading.value = true;
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw Exception('Kullanıcı oturumu bulunamadı');
        }

        await user.updateDisplayName(nameController.text.trim());

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İsim başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _logger.warning('İsim güncelleme hatası: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İsim güncellenirken bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Kullanıcı Ayarları',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil Bilgileri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                enabled: !isLoading.value,
                decoration: const InputDecoration(
                  labelText: 'İsim Soyisim',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen isminizi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value ? null : updateDisplayName,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('İsmi Güncelle'),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Şifre Değiştir',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: currentPasswordController,
                enabled: !isLoading.value,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isCurrentPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: !isLoading.value
                        ? () {
                            isCurrentPasswordVisible.value =
                                !isCurrentPasswordVisible.value;
                          }
                        : null,
                  ),
                ),
                obscureText: !isCurrentPasswordVisible.value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen mevcut şifrenizi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                enabled: !isLoading.value,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isNewPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: !isLoading.value
                        ? () {
                            isNewPasswordVisible.value =
                                !isNewPasswordVisible.value;
                          }
                        : null,
                  ),
                ),
                obscureText: !isNewPasswordVisible.value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmNewPasswordController,
                enabled: !isLoading.value,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: !isLoading.value
                        ? () {
                            isConfirmPasswordVisible.value =
                                !isConfirmPasswordVisible.value;
                          }
                        : null,
                  ),
                ),
                obscureText: !isConfirmPasswordVisible.value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi tekrar girin';
                  }
                  if (value != newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Şifreyi Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
