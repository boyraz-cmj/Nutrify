import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'product_detail_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../features/scanner/scanner_screen.dart';
import '../services/product_service.dart';
import '../core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart'; // Login ekranını import edelim
import 'settings/user_settings_screen.dart';

final barcodeProvider = StateProvider<String?>((ref) => null);
final productNameProvider = StateProvider<ProductInfo?>((ref) => null);

class ProductInfo {
  final String brandName;
  final String productName;

  ProductInfo(this.brandName, this.productName);
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final logger = Logger('HomeScreen');

    Future<void> getProductName(WidgetRef ref, String barcode) async {
      try {
        if (barcode.length != 13) {
          throw Exception('Barkod 13 haneli olmalıdır');
        }

        final productService = ref.read(productServiceProvider);
        final cachedProduct = await productService.getProductByBarcode(barcode);

        if (cachedProduct != null) {
          ref.read(productNameProvider.notifier).state = ProductInfo(
            cachedProduct.brandName,
            cachedProduct.productName,
          );

          if (!context.mounted) return;

          logger.info(
              'Cached Product Nutrition Claims: ${cachedProduct.nutritionClaims}');

          final Map<String, dynamic> productData = {
            'brandName': cachedProduct.brandName,
            'productName': cachedProduct.productName,
            'nutritionFacts': cachedProduct.nutritionFacts,
            'nutritionClaims': {
              'allergens': cachedProduct.nutritionClaims?.allergens ?? {},
              'dietaryInfo': cachedProduct.nutritionClaims?.dietaryInfo ?? {},
            },
          };

          logger.info('Prepared Product Data: ${json.encode(productData)}');

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: productData,
              ),
            ),
          );
          return;
        }

        const String baseUrl = 'http://10.32.3.7:3000';
        final uri = Uri.parse('$baseUrl/product-name/$barcode');
        logger.info('Requesting: $uri');

        final response =
            await http.get(uri).timeout(const Duration(seconds: 60));
        logger.info(
            'Response received. Status: ${response.statusCode}, Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          logger.info('API Response Data: ${json.encode(data)}');

          if (data is! Map<String, dynamic>) {
            throw Exception('Invalid response format');
          }

          final brandName = data['brandName'] as String?;
          final productName = data['productName'] as String?;
          final nutritionFacts =
              data['nutritionFacts'] as Map<String, dynamic>?;
          final nutritionClaims =
              data['nutritionClaims'] as Map<String, dynamic>? ??
                  {'allergens': {}, 'dietaryInfo': {}};

          if (brandName == null && productName == null) {
            throw Exception('Ürün bilgisi bulunamadı');
          }

          final Map<String, dynamic> productData = {
            'brandName': brandName ?? 'Marka bulunamadı',
            'productName': productName ?? 'Ürün adı bulunamadı',
            'nutritionFacts': nutritionFacts ?? {},
            'nutritionClaims': nutritionClaims,
          };

          logger.info('Prepared Product Data: ${json.encode(productData)}');

          await productService.saveProduct(barcode, productData);

          ref.read(productNameProvider.notifier).state = ProductInfo(
            brandName ?? 'Marka bulunamadı',
            productName ?? 'Ürün adı bulunamadı',
          );

          if (!context.mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: productData,
              ),
            ),
          );
        } else {
          throw Exception(
              'Failed to load product information: ${response.statusCode}');
        }
      } catch (e) {
        logger.severe('Error fetching product information', e);
        if (!context.mounted) return;

        String errorMessage;
        if (e is SocketException) {
          errorMessage = 'Bağlantı hatası: Sunucuya ulaşılamıyor.';
        } else if (e is TimeoutException) {
          errorMessage =
              'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
        } else if (e.toString().contains('Bilinmeyen barkod')) {
          errorMessage = 'Bu barkoda ait ürün bulunamadı.';
        } else if (e.toString().contains('Barkod 13 haneli olmalıdır')) {
          errorMessage = 'Barkod 13 haneli olmalıdır.';
        } else {
          errorMessage = 'Bir hata oluştu: ${e.toString()}';
        }

        ref.read(productNameProvider.notifier).state =
            ProductInfo('Hata', errorMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }

    Future<void> scanBarcode(WidgetRef ref) async {
      try {
        final String? barcodeScanRes = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => const ScannerScreen(),
          ),
        );

        if (barcodeScanRes != null && context.mounted) {
          // Loading göstergesi ekleyelim
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          try {
            ref.read(barcodeProvider.notifier).state = barcodeScanRes;
            await getProductName(ref, barcodeScanRes);
          } finally {
            // Loading göstergesini kaldır
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      } catch (e) {
        logger.warning('Barkod tarama hatası: $e');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barkod taranamadı. Lütfen tekrar deneyin.'),
          ),
        );
      }
    }

    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Container(
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
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: AppColors.primaryOrange,
                        radius: 40,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: AppColors.primaryOrange,
                ),
                title: const Text('Ayarlar'),
                onTap: () {
                  Navigator.pop(context); // Drawer'ı kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColors.primaryOrange,
                ),
                title: const Text('Çıkış Yap'),
                onTap: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      // Drawer'ı kapat ve login ekranına yönlendir
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false, // Tüm route stack'i temizle
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Çıkış yapılırken bir hata oluştu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          FirebaseAuth.instance.currentUser?.displayName != null
              ? 'Hoşgeldin ${FirebaseAuth.instance.currentUser!.displayName}'
              : 'Hoşgeldin',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
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
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Barkod veya ürün adı girin',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primaryOrange,
                    size: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onSubmitted: (value) => getProductName(ref, value),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ürün taramak için kamerayı kullanın',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => scanBarcode(ref),
          backgroundColor: AppColors.primaryOrange,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.primaryGreen,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Container(
          height: 56.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen,
                AppColors.primaryGreen.withOpacity(0.9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
