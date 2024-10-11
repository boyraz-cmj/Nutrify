import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_facts.dart';
import '../widgets/nutrition_facts_table.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionFacts = NutritionFacts.fromJson(product['nutriments'] ?? {});
    final nutriScore = product['nutrition_grade_fr'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ürün Detayları',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['productName'] ?? 'Ürün Adı Bulunamadı',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['brandName'] ?? 'Marka Bulunamadı',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _NutritionScoreWidget(score: nutriScore),
                  const SizedBox(height: 24),
                  Text(
                    'Besin Değerleri',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  NutritionFactsTable(nutritionFacts: nutritionFacts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionScoreWidget extends StatelessWidget {
  final String score;

  const _NutritionScoreWidget({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getColorForScore(score),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Nutri-Score: $score',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Color _getColorForScore(String score) {
    switch (score.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}