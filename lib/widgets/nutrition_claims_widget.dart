import 'package:flutter/material.dart';
import '../models/nutrition_claims.dart';

class NutritionClaimsWidget extends StatelessWidget {
  final NutritionClaims claims;

  const NutritionClaimsWidget({super.key, required this.claims});

  @override
  Widget build(BuildContext context) {
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
            _buildAllergenSection(
              'Free from:',
              claims.allergens.entries
                  .where((e) => e.value.toLowerCase().contains('free')),
              Icons.check_circle,
              Colors.green,
            ),
            _buildAllergenSection(
              'May contain:',
              claims.allergens.entries
                  .where((e) => e.value.toLowerCase().contains('may')),
              Icons.help,
              Colors.orange,
            ),
            const Divider(),
            _buildDietaryInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenSection(
    String title,
    Iterable<MapEntry<String, String>> allergens,
    IconData icon,
    Color color,
  ) {
    if (allergens.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        ...allergens.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(e.key),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDietaryInfo() {
    if (claims.dietaryInfo.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dietary Information:'),
        const SizedBox(height: 8),
        ...claims.dietaryInfo.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                Icon(
                  e.value ? Icons.check_circle : Icons.cancel,
                  color: e.value ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('${e.key} diet'),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 