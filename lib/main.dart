import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'dart:async';

final _logger = Logger('BarcodeScanner');

void main() {
  _setupLogging();
  runApp(const ProviderScope(child: MyApp()));
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barkod Okuyucu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BarcodeScanner(),
    );
  }
}

final barcodeProvider = StateProvider<String?>((ref) => null);
final productNameProvider = StateProvider<ProductInfo?>((ref) => null);

class BarcodeScanner extends ConsumerWidget {
  const BarcodeScanner({super.key});

  Future<void> scanBarcode(WidgetRef ref) async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'İptal',
      true,
      ScanMode.BARCODE,
    );

    if (barcodeScanRes != '-1') {
      ref.read(barcodeProvider.notifier).state = barcodeScanRes;
      await getProductName(ref, barcodeScanRes);
    }
  }

  Future<void> getProductName(WidgetRef ref, String barcode) async {
    try {
      const String baseUrl = 'http://10.32.18.172:3000'; // Localhost IP adresiniz

      final uri = Uri.parse('$baseUrl/product-name/$barcode');
      _logger.info('Requesting: $uri');

      _logger.info('Sending request to: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      _logger.info(
          'Response received. Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final brandName = data['brandName'];
        final productName = data['productName'];
        _logger.info('Brand name: $brandName, Product name: $productName');
        ref.read(productNameProvider.notifier).state = ProductInfo(brandName, productName);
      } else {
        throw Exception('Failed to load product information: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching product information', e);
      if (e is SocketException) {
        ref.read(productNameProvider.notifier).state =
            ProductInfo('Hata', 'Bağlantı hatası: Sunucuya ulaşılamıyor.');
      } else if (e is TimeoutException) {
        ref.read(productNameProvider.notifier).state =
            ProductInfo('Hata', 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');
      } else {
        ref.read(productNameProvider.notifier).state = ProductInfo('Hata', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barcode = ref.watch(barcodeProvider);
    final productInfo = ref.watch(productNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Okuyucu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => scanBarcode(ref),
              child: const Text('Barkod Tara'),
            ),
            const SizedBox(height: 20),
            if (barcode != null)
              SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Taranan Barkod: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: barcode),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (productInfo != null)
              Column(
                children: [
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Marka: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: productInfo.brandName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Ürün Adı: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: productInfo.productName),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ProductInfo {
  final String brandName;
  final String productName;

  ProductInfo(this.brandName, this.productName);
}
