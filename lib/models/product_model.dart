import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_claims.dart';

class Product {
  final String barcode;
  final String brandName;
  final String productName;
  final Map<String, dynamic> nutritionFacts;
  final NutritionClaims? nutritionClaims;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.barcode,
    required this.brandName,
    required this.productName,
    required this.nutritionFacts,
    this.nutritionClaims,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nutritionClaimsData = data['nutritionClaims'] as Map<String, dynamic>?;
    
    return Product(
      barcode: doc.id,
      brandName: data['brandName'] ?? '',
      productName: data['productName'] ?? '',
      nutritionFacts: data['nutritionFacts'] ?? {},
      nutritionClaims: nutritionClaimsData != null 
          ? NutritionClaims.fromJson(nutritionClaimsData)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final nutritionClaimsMap = nutritionClaims?.toJson();
    return {
      'brandName': brandName,
      'productName': productName,
      'nutritionFacts': nutritionFacts,
      'nutritionClaims': nutritionClaimsMap != null ? {
        'allergens': nutritionClaimsMap['allergens'] ?? {},
        'dietaryInfo': nutritionClaimsMap['dietaryInfo'] ?? {}
      } : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 