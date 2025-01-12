import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/product_model.dart';

final productServiceProvider = Provider((ref) => ProductService());

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final doc = await _firestore.collection('products').doc(barcode).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Firebase erişim izni hatası: Lütfen güvenlik kurallarını kontrol edin');
      }
      throw Exception('Firebase hatası: ${e.message}');
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<void> saveProduct(
      String barcode, Map<String, dynamic> productData) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('products').doc(barcode).set({
        ...productData,
        'createdAt': now,
        'updatedAt': now,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Firebase erişim izni hatası: Lütfen güvenlik kurallarını kontrol edin');
      }
      throw Exception('Firebase hatası: ${e.message}');
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // Test fonksiyonu
  Future<void> testFirebaseConnection() async {
    try {
      final testDoc = await _firestore.collection('test').doc('test').set({
        'test': 'Bağlantı başarılı',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Firebase bağlantısı başarılı');
    } catch (e) {
      print('Firebase bağlantı hatası: $e');
    }
  }
}
