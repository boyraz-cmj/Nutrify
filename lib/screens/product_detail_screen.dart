import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      'totalFat': 78.0,         // 78g (değiştirildi: 65g -> 78g)
      'saturatedFat': 20.0,     // 20g (aynı)
      'cholesterol': 300.0,     // 300mg (aynı)
      'sodium': 2300.0,         // 2300mg (aynı)
      'totalCarbohydrate': 275.0, // 275g (değiştirildi: 300g -> 275g)
      'dietaryFiber': 28.0,     // 28g
      'protein': 50.0,          // 50g (aynı)
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
                          _extractNumericValue(nutritionFacts['totalCarbohydrate']),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label ($percentage%)'),
              Text('${value.toStringAsFixed(1)}g'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRowWithPercentage(String label, String value, int? percentage) {
    // Değer ve birim arasındaki boşlukları temizle
    final cleanValue = value.replaceAll(RegExp(r'\s+'), '');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Label sol tarafta
          Expanded(
            flex: 3,
            child: Text(label),
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
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  cleanValue,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildIndentedNutritionRowWithPercentage(String label, String value, int? percentage) {
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
      return productName.substring(0, productName.length - brandName.length).trim();
    }
    // Eğer ürün adı marka adı ile başlıyorsa, marka adını kaldır
    if (productName.toLowerCase().startsWith(brandName.toLowerCase())) {
      return productName.substring(brandName.length).trim();
    }
    return productName;
  }
}
