import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_score.dart';
import '../services/scoring_service.dart';

enum NutrientStatus {
  positive,
  moderate,
  moderateNegative,
  negative,
}

final scoringService = ScoringService();

class ProductDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionFacts =
        product['nutritionFacts'] as Map<String, dynamic>? ?? {};
    final nutritionClaims =
        product['nutritionClaims'] as Map<String, dynamic>? ?? {};
    final allergens =
        nutritionClaims['allergens'] as Map<String, dynamic>? ?? {};
    final dietaryInfo =
        nutritionClaims['dietaryInfo'] as Map<String, dynamic>? ?? {};

    // Debug print to check the values
    print('Product Name: ${product['productName']}');
    print('Brand Name: ${product['brandName']}');

    final productScore = scoringService.calculateScore(
      nutritionFacts,
      nutritionClaims,
    );

    // Her besin değerinin durumunu hesapla
    final proteinStatus = _getProteinStatus(nutritionFacts['protein']);
    final fiberStatus = _getFiberStatus(nutritionFacts['dietaryFiber']);
    final saltStatus = _getSaltStatus(nutritionFacts['sodium']);
    final sugarStatus = _getSugarStatus(nutritionFacts['sugars']);
    final energyStatus = _getEnergyStatus(nutritionFacts['calories']);
    final saturatesStatus = _getSaturatesStatus(nutritionFacts['saturatedFat']);
    final carbsStatus = _getCarbsStatus(nutritionFacts['totalCarbohydrate']);

    // Pozitif ve negatif besinleri ayır
    final positiveNutrients = <Map<String, dynamic>>[];
    final negativeNutrients = <Map<String, dynamic>>[];

    void addNutrient({
      required IconData icon,
      required String title,
      required String subtitle,
      required String value,
      required NutrientStatus status,
    }) {
      if (status == NutrientStatus.positive ||
          status == NutrientStatus.moderate) {
        positiveNutrients.add({
          'icon': icon,
          'title': title,
          'subtitle': subtitle,
          'value': value,
          'status': status,
        });
      } else {
        negativeNutrients.add({
          'icon': icon,
          'title': title,
          'subtitle': subtitle,
          'value': value,
          'status': status,
        });
      }
    }

    // Protein
    addNutrient(
      icon: Icons.fitness_center,
      title: 'Protein',
      subtitle: _getProteinDescription(nutritionFacts['protein']),
      value:
          '${_extractNumericValue(nutritionFacts['protein']).toStringAsFixed(1)}g',
      status: proteinStatus,
    );

    // Lif
    addNutrient(
      icon: Icons.grass,
      title: 'Fibre',
      subtitle: _getFiberDescription(nutritionFacts['dietaryFiber']),
      value:
          '${_extractNumericValue(nutritionFacts['dietaryFiber']).toStringAsFixed(1)}g',
      status: fiberStatus,
    );

    // Tuz
    addNutrient(
      icon: Icons.soup_kitchen,
      title: 'Salt',
      subtitle: _getSaltDescription(nutritionFacts['sodium']),
      value:
          '${_extractNumericValue(nutritionFacts['sodium']).toStringAsFixed(1)}g',
      status: saltStatus,
    );

    // Şeker
    addNutrient(
      icon: Icons.cookie,
      title: 'Sugar',
      subtitle: _getSugarDescription(nutritionFacts['sugars']),
      value:
          '${_extractNumericValue(nutritionFacts['sugars']).toStringAsFixed(1)}g',
      status: sugarStatus,
    );

    // Enerji
    addNutrient(
      icon: Icons.local_fire_department_outlined,
      title: 'Energy',
      subtitle: _getEnergyDescription(nutritionFacts['calories']),
      value:
          '${_extractNumericValue(nutritionFacts['calories']).toStringAsFixed(0)} kcal',
      status: energyStatus,
    );

    // Doymuş Yağ
    addNutrient(
      icon: Icons.water_drop,
      title: 'Saturates',
      subtitle: _getSaturatesDescription(nutritionFacts['saturatedFat']),
      value:
          '${_extractNumericValue(nutritionFacts['saturatedFat']).toStringAsFixed(1)}g',
      status: saturatesStatus,
    );

    // Karbonhidrat
    addNutrient(
      icon: Icons.grain,
      title: 'Carbohydrates',
      subtitle: _getCarbsDescription(nutritionFacts['totalCarbohydrate']),
      value:
          '${_extractNumericValue(nutritionFacts['totalCarbohydrate']).toStringAsFixed(1)}g',
      status: _getCarbsStatus(nutritionFacts['totalCarbohydrate']),
    );

    // Toplam Yağ
    final totalFatStatus = _getTotalFatStatus(nutritionFacts['totalFat']);
    addNutrient(
      icon: Icons.water_drop,
      title: 'Total Fat',
      subtitle: _getTotalFatDescription(nutritionFacts['totalFat']),
      value:
          '${_extractNumericValue(nutritionFacts['totalFat']).toStringAsFixed(1)}g',
      status: totalFatStatus,
    );

    // Kolesterol
    final cholesterolStatus =
        _getCholesterolStatus(nutritionFacts['cholesterol']);
    addNutrient(
      icon: Icons.monitor_heart_outlined,
      title: 'Cholesterol',
      subtitle: _getCholesterolDescription(nutritionFacts['cholesterol']),
      value:
          '${_extractNumericValue(nutritionFacts['cholesterol']).toStringAsFixed(1)}mg',
      status: cholesterolStatus,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanProductName(
                      product['productName'] as String? ?? '',
                      product['brandName'] as String? ?? '',
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                  ),
                  if (product['brandName'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        product['brandName'] as String,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getNutriScoreColor(productScore.nutriscore),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${productScore.totalScore.round()}/100',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                productScore.nutriscore,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getNutriScoreDescription(productScore.nutriscore),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Positives Section
            if (positiveNutrients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Positives',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                        ),
                        Text(
                          'per 100 g',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...positiveNutrients.map((nutrient) => _buildNutrientRow(
                          icon: nutrient['icon'] as IconData,
                          title: nutrient['title'] as String,
                          subtitle: nutrient['subtitle'] as String,
                          value: nutrient['value'] as String,
                          status: nutrient['status'] as NutrientStatus,
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Negatives Section
            if (negativeNutrients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Negatives',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                        ),
                        Text(
                          'per 100 g',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...negativeNutrients.map((nutrient) => _buildNutrientRow(
                          icon: nutrient['icon'] as IconData,
                          title: nutrient['title'] as String,
                          subtitle: nutrient['subtitle'] as String,
                          value: nutrient['value'] as String,
                          status: nutrient['status'] as NutrientStatus,
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Allergens Section
            if (allergens.entries.any((entry) =>
                !entry.value.toString().toLowerCase().contains('free')))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allergens',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ...allergens.entries
                        .where((entry) => !entry.value
                            .toString()
                            .toLowerCase()
                            .contains('free'))
                        .map((entry) {
                      final allergen = entry.key;
                      final status = entry.value.toString().toLowerCase();
                      IconData icon;
                      NutrientStatus nutrientStatus;
                      String description;

                      if (status.contains('may')) {
                        icon = Icons.warning_amber_rounded;
                        nutrientStatus = NutrientStatus.moderate;
                        description = 'May contain traces';
                      } else {
                        icon = Icons.warning_rounded;
                        nutrientStatus = NutrientStatus.negative;
                        description =
                            'Contains ${allergen.toString().toLowerCase()}';
                      }

                      return _buildNutrientRow(
                        icon: icon,
                        title: _capitalizeFirst(allergen.toString()),
                        subtitle: description,
                        value: '',
                        status: nutrientStatus,
                      );
                    }).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Dietary Information Section
            if (dietaryInfo.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dietary Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ...dietaryInfo.entries.map((entry) {
                      final diet = entry.key;
                      final suitable = entry.value as bool;
                      return _buildNutrientRow(
                        icon: suitable
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        title: _capitalizeFirst(diet.toString()),
                        subtitle: suitable
                            ? 'Suitable for this diet'
                            : 'Not suitable for this diet',
                        value: '',
                        status: suitable
                            ? NutrientStatus.positive
                            : NutrientStatus.negative,
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required NutrientStatus status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black87),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (value.isNotEmpty) ...[
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(NutrientStatus status) {
    switch (status) {
      case NutrientStatus.positive:
        return const Color(0xFF1E8F4E); // Dark green
      case NutrientStatus.moderate:
        return const Color(0xFF85BB2F); // Light green
      case NutrientStatus.moderateNegative:
        return const Color(0xFFFECB02); // Yellow
      case NutrientStatus.negative:
        return const Color(0xFFE63E11); // Red
    }
  }

  NutrientStatus _getProteinStatus(dynamic protein) {
    final value = _extractNumericValue(protein);
    if (value >= 8) return NutrientStatus.positive;
    if (value >= 6) return NutrientStatus.moderate;
    if (value >= 4) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  NutrientStatus _getFiberStatus(dynamic fiber) {
    final value = _extractNumericValue(fiber);
    if (value >= 4) return NutrientStatus.positive;
    if (value >= 3) return NutrientStatus.moderate;
    if (value >= 2) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  NutrientStatus _getSaltStatus(dynamic sodium) {
    final value = _extractNumericValue(sodium);
    if (value <= 0.3) return NutrientStatus.positive;
    if (value <= 0.5) return NutrientStatus.moderate;
    if (value <= 0.8) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  NutrientStatus _getSugarStatus(dynamic sugar) {
    final value = _extractNumericValue(sugar);
    if (value <= 5) return NutrientStatus.positive;
    if (value <= 10) return NutrientStatus.moderate;
    if (value <= 15) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  NutrientStatus _getEnergyStatus(dynamic calories) {
    final value = _extractNumericValue(calories);
    if (value <= 250) return NutrientStatus.positive;
    if (value <= 350) return NutrientStatus.moderate;
    if (value <= 450) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  NutrientStatus _getSaturatesStatus(dynamic saturates) {
    final value = _extractNumericValue(saturates);
    if (value <= 1.5) return NutrientStatus.positive;
    if (value <= 3) return NutrientStatus.moderate;
    if (value <= 5) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  String _getProteinDescription(dynamic protein) {
    final value = _extractNumericValue(protein);
    if (value >= 8) return 'Excellent amount of protein';
    if (value >= 6) return 'Good amount of protein';
    if (value >= 4) return 'Low amount of protein';
    return 'Very low in protein';
  }

  String _getFiberDescription(dynamic fiber) {
    final value = _extractNumericValue(fiber);
    if (value >= 4) return 'Excellent amount of fibre';
    if (value >= 3) return 'Good amount of fibre';
    if (value >= 2) return 'Low in fibre';
    return 'Very low in fibre';
  }

  String _getSaltDescription(dynamic sodium) {
    final value = _extractNumericValue(sodium);
    if (value <= 0.3) return 'Very low salt';
    if (value <= 0.5) return 'Low salt';
    if (value <= 0.8) return 'High salt';
    return 'Very high salt';
  }

  String _getSugarDescription(dynamic sugar) {
    final value = _extractNumericValue(sugar);
    if (value <= 5) return 'Very low sugar';
    if (value <= 10) return 'Low sugar';
    if (value <= 15) return 'High sugar';
    return 'Very high sugar';
  }

  String _getEnergyDescription(dynamic calories) {
    final value = _extractNumericValue(calories);
    if (value <= 250) return 'Very low caloric';
    if (value <= 350) return 'Low caloric';
    if (value <= 450) return 'High caloric';
    return 'Very high caloric';
  }

  String _getSaturatesDescription(dynamic saturates) {
    final value = _extractNumericValue(saturates);
    if (value <= 1.5) return 'Very low in saturates';
    if (value <= 3) return 'Low in saturates';
    if (value <= 5) return 'High in saturates';
    return 'Very high in saturates';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF1B5E20); // Koyu yeşil
    if (score >= 60) return const Color(0xFF8BC34A); // Açık yeşil
    if (score >= 40) return const Color(0xFFFFD600); // Sarı
    return const Color(0xFFE53935); // Kırmızı
  }

  String _getScoreDescription(String nutriscore) {
    switch (nutriscore.toUpperCase()) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Good';
      case 'C':
        return 'Average';
      case 'D':
        return 'Poor';
      case 'E':
        return 'Bad';
      default:
        return 'Unknown';
    }
  }

  double _extractNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(value);
      return match != null ? double.parse(match.group(1)!) : 0;
    }
    return 0;
  }

  String _cleanProductName(String productName, String brandName) {
    if (productName.isEmpty) return 'Unknown Product';
    if (brandName.isEmpty) return productName;

    if (productName.toLowerCase().contains(brandName.toLowerCase())) {
      return productName.trim();
    }
    return productName;
  }

  NutrientStatus _getCarbsStatus(dynamic carbs) {
    final value = _extractNumericValue(carbs);
    if (value >= 35) return NutrientStatus.negative; // Very high - worst (red)
    if (value >= 20)
      return NutrientStatus.moderateNegative; // High - bad (yellow)
    if (value >= 10) return NutrientStatus.moderate; // Low - good (light green)
    return NutrientStatus.positive; // Very low - best (dark green)
  }

  String _getCarbsDescription(dynamic carbs) {
    final value = _extractNumericValue(carbs);
    if (value >= 35) return 'Very high in carbohydrates';
    if (value >= 20) return 'High in carbohydrates';
    if (value >= 10) return 'Low in carbohydrates';
    return 'Very low in carbohydrates';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  NutrientStatus _getTotalFatStatus(dynamic totalFat) {
    final value = _extractNumericValue(totalFat);
    if (value <= 3) return NutrientStatus.positive;
    if (value <= 6) return NutrientStatus.moderate;
    if (value <= 10) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  String _getTotalFatDescription(dynamic totalFat) {
    final value = _extractNumericValue(totalFat);
    if (value <= 3) return 'Very low in fat';
    if (value <= 6) return 'Low in fat';
    if (value <= 10) return 'High in fat';
    return 'Very high in fat';
  }

  NutrientStatus _getCholesterolStatus(dynamic cholesterol) {
    final value = _extractNumericValue(cholesterol);
    if (value <= 20) return NutrientStatus.positive;
    if (value <= 40) return NutrientStatus.moderate;
    if (value <= 60) return NutrientStatus.moderateNegative;
    return NutrientStatus.negative;
  }

  String _getCholesterolDescription(dynamic cholesterol) {
    final value = _extractNumericValue(cholesterol);
    if (value <= 20) return 'Very low cholesterol';
    if (value <= 40) return 'Low cholesterol';
    if (value <= 60) return 'High cholesterol';
    return 'Very high cholesterol';
  }

  Color _getNutriScoreColor(String nutriScore) {
    switch (nutriScore.toUpperCase()) {
      case 'A':
        return const Color(0xFF1E8F4E); // Dark green
      case 'B':
        return const Color(0xFF85BB2F); // Light green
      case 'C':
        return const Color(0xFFFECB02); // Yellow
      case 'D':
        return const Color(0xFFF39A1A); // Orange
      case 'E':
        return const Color(0xFFE63E11); // Red
      default:
        return Colors.grey;
    }
  }

  String _getNutriScoreDescription(String nutriScore) {
    switch (nutriScore.toUpperCase()) {
      case 'A':
        return 'Excellent nutritional quality';
      case 'B':
        return 'Good nutritional quality';
      case 'C':
        return 'Average nutritional quality';
      case 'D':
        return 'Poor nutritional quality';
      case 'E':
        return 'Bad nutritional quality';
      default:
        return 'Unknown nutritional quality';
    }
  }
}
