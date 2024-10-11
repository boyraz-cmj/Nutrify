import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductService {
  final String baseUrl = 'https://world.openfoodfacts.org/api/v0/product/';

  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    final response = await http.get(Uri.parse('$baseUrl$barcode.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 1) {
        return data['product'];
      } else {
        throw Exception('Ürün bulunamadı');
      }
    } else {
      throw Exception('Ürün yüklenirken bir hata oluştu');
    }
  }
}

final productServiceProvider = Provider<ProductService>((ref) => ProductService());