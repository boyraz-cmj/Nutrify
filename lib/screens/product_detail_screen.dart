import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/nutrition_claims_widget.dart';
import '../models/nutrition_claims.dart';
import '../core/theme/app_colors.dart';
import 'dart:convert';

class ProductDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Product Details: ${json.encode(product)}');
    print('Nutrition Claims Data: ${json.encode(product['nutritionClaims'])}');

    final nutritionFacts =
        product['nutritionFacts'] as Map<String, dynamic>? ?? {};

    // Makrobesin değerlerini al ve hesapla
    final totalFat = _extractNumericValue(nutritionFacts['totalFat']);
    final totalCarbs =
        _extractNumericValue(nutritionFacts['totalCarbohydrate']);
    final protein = _extractNumericValue(nutritionFacts['protein']);

    // Kalori hesaplamaları (1g yağ = 9 kcal, 1g protein/karbonhidrat = 4 kcal)
    final fatCalories = totalFat * 9;
    final carbCalories = totalCarbs * 4;
    final proteinCalories = protein * 4;
    final totalCalories = fatCalories + carbCalories + proteinCalories;

    // Yüzde hesaplamaları
    final fatPercentage = (fatCalories / totalCalories * 100).round();
    final carbPercentage = (carbCalories / totalCalories * 100).round();
    final proteinPercentage = (proteinCalories / totalCalories * 100).round();

    // Günlük referans değerleri
    final Map<String, double> dailyValues = {
      'totalFat': 78.0, // 78g (değiştirildi: 65g -> 78g)
      'saturatedFat': 20.0, // 20g (aynı)
      'cholesterol': 300.0, // 300mg (aynı)
      'sodium': 2300.0, // 2300mg (aynı)
      'totalCarbohydrate': 275.0, // 275g (değiştirildi: 300g -> 275g)
      'dietaryFiber': 28.0, // 28g
      'protein': 50.0, // 50g (aynı)
    };

    int _calculateDailyValue(double value, String nutrient) {
      final referenceValue = dailyValues[nutrient] ?? 100.0;
      return ((value / referenceValue) * 100).round();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product Details',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cleanProductName(
                  product['productName'] ?? 'Product Name Not Found',
                  product['brandName'] ?? '',
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${product['brandName'] ?? 'Brand Not Found'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),

              // Makrobesin dağılımı kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Macronutrient Distribution',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildMacroRow(
                        'Fat',
                        totalFat,
                        fatPercentage,
                        Colors.red.shade300,
                      ),
                      _buildMacroRow(
                        'Carbs',
                        totalCarbs,
                        carbPercentage,
                        Colors.blue.shade300,
                      ),
                      _buildMacroRow(
                        'Protein',
                        protein,
                        proteinPercentage,
                        Colors.green.shade300,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Nutrition Facts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Besin değerleri kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNutritionRow(
                        'Serving Size',
                        nutritionFacts['servingSize'] ?? '100g',
                      ),
                      const Divider(),
                      _buildNutritionRowWithPercentage(
                        'Calories',
                        nutritionFacts['calories'] ?? '0',
                        null,
                      ),
                      const Divider(),
                      _buildNutritionRowWithPercentage(
                        'Total Fat',
                        nutritionFacts['totalFat'] ?? '0g',
                        _calculateDailyValue(
                          _extractNumericValue(nutritionFacts['totalFat']),
                          'totalFat',
                        ),
                      ),
                      _buildIndentedNutritionRowWithPercentage(
                        'Saturated Fat',
                        nutritionFacts['saturatedFat'] ?? '0g',
                        _calculateDailyValue(
                          _extractNumericValue(nutritionFacts['saturatedFat']),
                          'saturatedFat',
                        ),
                      ),
                      _buildIndentedNutritionRow(
                        'Trans Fat',
                        nutritionFacts['transFat'] ?? '0g',
                      ),
                      const Divider(),
                      _buildNutritionRowWithPercentage(
                        'Cholesterol',
                        nutritionFacts['cholesterol'] ?? '0mg',
                        _calculateDailyValue(
                          _extractNumericValue(nutritionFacts['cholesterol']),
                          'cholesterol',
                        ),
                      ),
                      const Divider(),
                      _buildNutritionRowWithPercentage(
                        'Sodium',
                        nutritionFacts['sodium'] ?? '0mg',
                        _calculateDailyValue(
                          _extractNumericValue(nutritionFacts['sodium']),
                          'sodium',
                        ),
                      ),
                      const Divider(),
                      _buildNutritionRowWithPercentage(
                        'Total Carbohydrate',
                        nutritionFacts['totalCarbohydrate'] ?? '0g',
                        _calculateDailyValue(
                          _extractNumericValue(
                              nutritionFacts['totalCarbohydrate']),
                          'totalCarbohydrate',
                        ),
                      ),
                      _buildIndentedNutritionRow(
                        'Dietary Fiber',
                        nutritionFacts['dietaryFiber'] ?? '0g',
                      ),
                      _buildIndentedNutritionRow(
                        'Sugars',
                        nutritionFacts['sugars'] ?? '0g',
                      ),
                      const Divider(),
                      _buildNutritionRowWithPercentage(
                        'Protein',
                        nutritionFacts['protein'] ?? '0g',
                        _calculateDailyValue(
                          _extractNumericValue(nutritionFacts['protein']),
                          'protein',
                        ),
                      ),
                      const Divider(),
                      _buildNutritionRow(
                        'Vitamin D',
                        nutritionFacts['vitaminD'] ?? '0mcg',
                      ),
                      _buildNutritionRow(
                        'Calcium',
                        nutritionFacts['calcium'] ?? '0mg',
                      ),
                      _buildNutritionRow(
                        'Iron',
                        nutritionFacts['iron'] ?? '0mg',
                      ),
                      _buildNutritionRow(
                        'Potassium',
                        nutritionFacts['potassium'] ?? '0mg',
                      ),
                    ],
                  ),
                ),
              ),

              // Nutrition Claims kartı
              Builder(
                builder: (context) {
                  try {
                    // Nutrition claims verilerini kontrol et
                    final nutritionClaimsData = product['nutritionClaims'];
                    if (nutritionClaimsData == null)
                      return const SizedBox.shrink();

                    // Tip kontrolü ve dönüşümü
                    Map<String, dynamic> nutritionClaims;
                    if (nutritionClaimsData is Map) {
                      nutritionClaims =
                          Map<String, dynamic>.from(nutritionClaimsData);
                    } else {
                      print(
                          'Invalid nutrition claims data type: ${nutritionClaimsData.runtimeType}');
                      return const SizedBox.shrink();
                    }

                    final allergens = (nutritionClaims['allergens'] is Map)
                        ? Map<String, dynamic>.from(
                            nutritionClaims['allergens'] as Map)
                        : <String, dynamic>{};

                    final dietaryInfo = (nutritionClaims['dietaryInfo'] is Map)
                        ? Map<String, dynamic>.from(
                            nutritionClaims['dietaryInfo'] as Map)
                        : <String, dynamic>{};

                    // Debug için
                    print('Allergens: $allergens');
                    print('Dietary Info: $dietaryInfo');

                    // Eğer hem allergens hem de dietaryInfo boşsa, hiçbir şey gösterme
                    if (allergens.isEmpty && dietaryInfo.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition Claims',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            // Free from section
                            if (allergens.entries
                                .where((e) => e.value
                                    .toString()
                                    .toLowerCase()
                                    .contains('free'))
                                .isNotEmpty)
                              Builder(
                                builder: (context) {
                                  try {
                                    final freeFromItems = allergens.entries
                                        .where((e) => e.value
                                            .toString()
                                            .toLowerCase()
                                            .contains('free'))
                                        .toList();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('This food is free from:'),
                                        const SizedBox(height: 8),
                                        ...freeFromItems.map((e) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16, bottom: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(e.key
                                                      .toString()
                                                      .replaceAll(
                                                          RegExp(r'^\s+|\s+$'),
                                                          '')),
                                                ],
                                              ),
                                            )),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  } catch (e) {
                                    print('Error in Free from section: $e');
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),

                            // May contain section
                            if (allergens.entries
                                .where((e) => e.value
                                    .toString()
                                    .toLowerCase()
                                    .contains('may'))
                                .isNotEmpty)
                              Builder(
                                builder: (context) {
                                  try {
                                    final mayContainItems = allergens.entries
                                        .where((e) => e.value
                                            .toString()
                                            .toLowerCase()
                                            .contains('may'))
                                        .toList();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('This food may contain:'),
                                        const SizedBox(height: 8),
                                        ...mayContainItems.map((e) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16, bottom: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.help,
                                                    color: Colors.orange,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(e.key
                                                      .toString()
                                                      .replaceAll(
                                                          RegExp(r'^\s+|\s+$'),
                                                          '')),
                                                ],
                                              ),
                                            )),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  } catch (e) {
                                    print('Error in May contain section: $e');
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),

                            // Dietary Information
                            if (dietaryInfo.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  try {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Dietary Information:'),
                                        const SizedBox(height: 8),
                                        ...dietaryInfo.entries
                                            .map((e) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 16, bottom: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        e.value == false
                                                            ? Icons.cancel
                                                            : Icons
                                                                .check_circle,
                                                        color: e.value == false
                                                            ? Colors.red
                                                            : Colors.green,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text('${e.key} diet'),
                                                    ],
                                                  ),
                                                )),
                                      ],
                                    );
                                  } catch (e) {
                                    print(
                                        'Error in Dietary Information section: $e');
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Error in nutrition claims card: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow(
      String label, double value, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getMacroIcon(label),
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$label ($percentage%)',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${value.toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRowWithPercentage(
      String label, String value, int? percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            _getNutritionIcon(label),
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Row(
                  children: [
                    Text(value),
                    if (percentage != null) ...[
                      const SizedBox(width: 8),
                      Text('${percentage.toString()}%'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  double _extractNumericValue(String? value) {
    if (value == null) return 0;
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(value);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  Widget _buildIndentedNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndentedNutritionRowWithPercentage(
      String label, String value, int? percentage) {
    // Değer ve birim arasındaki boşlukları temizle
    final cleanValue = value.replaceAll(RegExp(r'\s+'), '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
      child: Row(
        children: [
          // Label sol tarafta (girintili)
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Yüzde ve değer sağ tarafta
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (percentage != null) ...[
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  cleanValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _cleanProductName(String productName, String brandName) {
    // Eğer ürün adı marka adı ile bitiyorsa, marka adını kaldır
    if (productName.toLowerCase().endsWith(brandName.toLowerCase())) {
      return productName
          .substring(0, productName.length - brandName.length)
          .trim();
    }
    // Eğer ürün adı marka adı ile başlıyorsa, marka adını kaldır
    if (productName.toLowerCase().startsWith(brandName.toLowerCase())) {
      return productName.substring(brandName.length).trim();
    }
    return productName;
  }

  IconData _getMacroIcon(String label) {
    switch (label.toLowerCase()) {
      case 'fat':
        return Icons.opacity; // Yağ damlası ikonu
      case 'carbs':
        return Icons.grain; // Tahıl ikonu
      case 'protein':
        return Icons.fitness_center; // Protein için ağırlık ikonu
      default:
        return Icons.circle;
    }
  }

  IconData _getNutritionIcon(String label) {
    switch (label.toLowerCase()) {
      case 'calories':
        return Icons.local_fire_department; // Kalori için ateş ikonu
      case 'total fat':
        return Icons.opacity; // Yağ damlası ikonu
      case 'saturated fat':
        return Icons.opacity_outlined; // Doymuş yağ için farklı yağ ikonu
      case 'trans fat':
        return Icons.warning_outlined; // Trans yağ için uyarı ikonu
      case 'cholesterol':
        return Icons.medical_services_outlined; // Kolesterol için medikal ikonu
      case 'sodium':
        return Icons.restaurant; // Sodyum için tuz/yemek ikonu
      case 'total carbohydrate':
        return Icons.grain; // Karbonhidrat için tahıl ikonu
      case 'dietary fiber':
        return Icons.grass; // Lif için bitki ikonu
      case 'sugars':
        return Icons.cake; // Şeker için tatlı ikonu
      case 'protein':
        return Icons.fitness_center; // Protein için ağırlık ikonu
      case 'serving size':
        return Icons.restaurant_menu; // Porsiyon için tabak ikonu
      default:
        return Icons.info_outline;
    }
  }
}
