import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'product_detail_screen.dart';

// Diğer import'ları kaldırdık

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
        // Barkod uzunluğu kontrolü
        if (barcode.length != 13) {
          throw Exception('Barkod 13 haneli olmalıdır');
        }

        const String baseUrl = 'http://10.32.18.172:3000'; // Localhost IP adresiniz

        final uri = Uri.parse('$baseUrl/product-name/$barcode');
        logger.info('Requesting: $uri');

        logger.info('Sending request to: $uri');
        final response = await http.get(uri).timeout(const Duration(seconds: 60));
        logger.info(
            'Response received. Status: ${response.statusCode}, Body: ${response.body}');

        if (response.statusCode == 200) {
          if (response.body.contains('<div class="content">Unknown barcode</div>')) {
            throw Exception('Bilinmeyen barkod');
          }
          if (response.body.contains('<span id="barcode_number-error" class="is-invalid">Barcode must be 13 digits</span>')) {
            throw Exception('Barkod 13 haneli olmalıdır');
          }

          final data = json.decode(response.body);
          final brandName = data['brandName'];
          final productName = data['productName'];
          logger.info('Brand name: $brandName, Product name: $productName');
          ref.read(productNameProvider.notifier).state = ProductInfo(brandName, productName);
          
          // Ürün detay sayfasına yönlendirme
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: data),
            ),
          );
        } else {
          throw Exception('Failed to load product information: ${response.statusCode}');
        }
      } catch (e) {
        logger.severe('Error fetching product information', e);
        if (!context.mounted) return;
        
        String errorMessage;
        if (e is SocketException) {
          errorMessage = 'Bağlantı hatası: Sunucuya ulaşılamıyor.';
        } else if (e is TimeoutException) {
          errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
        } else if (e.toString().contains('Bilinmeyen barkod')) {
          errorMessage = 'Bu barkoda ait ürün bulunamadı.';
        } else if (e.toString().contains('Barkod 13 haneli olmalıdır')) {
          errorMessage = 'Barkod 13 haneli olmalıdır.';
        } else {
          errorMessage = 'Bir hata oluştu: ${e.toString()}';
        }

        ref.read(productNameProvider.notifier).state = ProductInfo('Hata', errorMessage);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }

    Future<void> scanBarcode(WidgetRef ref) async {
      String barcodeScanRes;
      try {
        barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666',
          'İptal',
          true,
          ScanMode.BARCODE,
        );

        if (barcodeScanRes != '-1') {
          ref.read(barcodeProvider.notifier).state = barcodeScanRes;
          await getProductName(ref, barcodeScanRes);
        }
      } catch (e) {
        logger.warning('Barkod tarama hatası: $e');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barkod taranamadı. Lütfen tekrar deneyin.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ürün Tarayıcı',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Barkod veya ürün adı girin',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
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
                  Icon(
                    Icons.qr_code_scanner,
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ürün taramak için kamerayı kullanın',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => scanBarcode(ref),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamerayı Aç'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}