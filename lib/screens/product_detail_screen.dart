import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_score.dart';
import '../services/scoring_service.dart';

enum NutrientStatus {
  positive,
  moderate,
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
    final productScore = scoringService.calculateScore(
      nutritionFacts,
      product['nutritionClaims'] as Map<String, dynamic>?,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanProductName(
                      product['productName'] ?? 'Product Name Not Found',
                      product['brandName'] ?? '',
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    product['brandName'] ?? 'Brand Not Found',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getScoreColor(productScore.totalScore),
                          borderRadius: BorderRadius.circular(12),
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getScoreDescription(productScore.nutriscore),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Positives Section
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
                  _buildNutrientRow(
                    icon: Icons.check_circle_outline,
                    title: 'No additives',
                    subtitle: 'No hazardous substances',
                    value: '',
                    status: NutrientStatus.positive,
                  ),
                  _buildNutrientRow(
                    icon: Icons.fitness_center,
                    title: 'Protein',
                    subtitle: _getProteinDescription(nutritionFacts['protein']),
                    value:
                        '${_extractNumericValue(nutritionFacts['protein']).toStringAsFixed(1)}g',
                    status: _getProteinStatus(nutritionFacts['protein']),
                  ),
                  _buildNutrientRow(
                    icon: Icons.grass,
                    title: 'Fibre',
                    subtitle:
                        _getFiberDescription(nutritionFacts['dietaryFiber']),
                    value:
                        '${_extractNumericValue(nutritionFacts['dietaryFiber']).toStringAsFixed(1)}g',
                    status: _getFiberStatus(nutritionFacts['dietaryFiber']),
                  ),
                  _buildNutrientRow(
                    icon: Icons.soup_kitchen,
                    title: 'Salt',
                    subtitle: _getSaltDescription(nutritionFacts['sodium']),
                    value:
                        '${_extractNumericValue(nutritionFacts['sodium']).toStringAsFixed(1)}g',
                    status: _getSaltStatus(nutritionFacts['sodium']),
                  ),
                  _buildNutrientRow(
                    icon: Icons.cookie,
                    title: 'Sugar',
                    subtitle: _getSugarDescription(nutritionFacts['sugars']),
                    value:
                        '${_extractNumericValue(nutritionFacts['sugars']).toStringAsFixed(1)}g',
                    status: _getSugarStatus(nutritionFacts['sugars']),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Negatives Section
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
                  _buildNutrientRow(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Energy',
                    subtitle: _getEnergyDescription(nutritionFacts['calories']),
                    value:
                        '${_extractNumericValue(nutritionFacts['calories']).toStringAsFixed(0)} kcal',
                    status: _getEnergyStatus(nutritionFacts['calories']),
                  ),
                  _buildNutrientRow(
                    icon: Icons.water_drop,
                    title: 'Saturates',
                    subtitle: _getSaturatesDescription(
                        nutritionFacts['saturatedFat']),
                    value:
                        '${_extractNumericValue(nutritionFacts['saturatedFat']).toStringAsFixed(1)}g',
                    status: _getSaturatesStatus(nutritionFacts['saturatedFat']),
                  ),
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
          Icon(
            icon,
            size: 22,
            color: Colors.black87,
          ),
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
        return const Color(0xFF1B5E20); // Koyu yeşil
      case NutrientStatus.moderate:
        return const Color(0xFF8BC34A); // Açık yeşil
      case NutrientStatus.negative:
        return const Color(0xFFE53935); // Kırmızı
    }
  }

  NutrientStatus _getProteinStatus(dynamic protein) {
    final value = _extractNumericValue(protein);
    if (value >= 8) return NutrientStatus.positive;
    if (value >= 6) return NutrientStatus.moderate;
    return NutrientStatus.negative;
  }

  NutrientStatus _getFiberStatus(dynamic fiber) {
    final value = _extractNumericValue(fiber);
    if (value >= 3) return NutrientStatus.positive;
    if (value >= 2) return NutrientStatus.moderate;
    return NutrientStatus.negative;
  }

  NutrientStatus _getSaltStatus(dynamic sodium) {
    final value = _extractNumericValue(sodium);
    if (value <= 0.3) return NutrientStatus.positive;
    if (value <= 0.5) return NutrientStatus.moderate;
    return NutrientStatus.negative;
  }

  NutrientStatus _getSugarStatus(dynamic sugar) {
    final value = _extractNumericValue(sugar);
    if (value <= 5) return NutrientStatus.positive;
    if (value <= 10) return NutrientStatus.moderate;
    return NutrientStatus.negative;
  }

  NutrientStatus _getEnergyStatus(dynamic calories) {
    final value = _extractNumericValue(calories);
    if (value <= 300) return NutrientStatus.positive;
    if (value <= 400) return NutrientStatus.moderate;
    return NutrientStatus.negative;
  }

  NutrientStatus _getSaturatesStatus(dynamic saturates) {
    final value = _extractNumericValue(saturates);
    if (value <= 2) return NutrientStatus.positive;
    if (value <= 4) return NutrientStatus.moderate;
    return NutrientStatus.negative;
  }

  String _getProteinDescription(dynamic protein) {
    final value = _extractNumericValue(protein);
    if (value >= 8) return 'Excellent amount of protein';
    if (value >= 6) return 'Good amount of protein';
    return 'Low amount of protein';
  }

  String _getFiberDescription(dynamic fiber) {
    final value = _extractNumericValue(fiber);
    if (value >= 3) return 'Excellent amount of fibre';
    if (value >= 2) return 'Good amount of fibre';
    return 'Low in fibre';
  }

  String _getSaltDescription(dynamic sodium) {
    final value = _extractNumericValue(sodium);
    if (value <= 0.3) return 'Low salt';
    if (value <= 0.5) return 'Moderate salt';
    return 'High salt';
  }

  String _getSugarDescription(dynamic sugar) {
    final value = _extractNumericValue(sugar);
    if (value <= 5) return 'Low impact';
    if (value <= 10) return 'Moderate impact';
    return 'High impact';
  }

  String _getEnergyDescription(dynamic calories) {
    final value = _extractNumericValue(calories);
    if (value <= 300) return 'Low caloric';
    if (value <= 400) return 'Moderate caloric';
    return 'A bit too caloric';
  }

  String _getSaturatesDescription(dynamic saturates) {
    final value = _extractNumericValue(saturates);
    if (value <= 2) return 'Low in saturates';
    if (value <= 4) return 'Moderate in saturates';
    return 'A little too fatty';
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
    if (productName.toLowerCase().endsWith(brandName.toLowerCase())) {
      return productName
          .substring(0, productName.length - brandName.length)
          .trim();
    }
    if (productName.toLowerCase().startsWith(brandName.toLowerCase())) {
      return productName.substring(brandName.length).trim();
    }
    return productName;
  }
}
