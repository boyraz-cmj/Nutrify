import 'package:flutter/material.dart';
import '../models/nutrition_facts.dart';

class NutritionFactsTable extends StatelessWidget {
  final NutritionFacts nutritionFacts;

  const NutritionFactsTable({Key? key, required this.nutritionFacts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      children: [
        _buildTableRow('Enerji', '${nutritionFacts.energy.toStringAsFixed(1)} kcal'),
        _buildTableRow('Yağ', '${nutritionFacts.fat.toStringAsFixed(1)} g'),
        _buildTableRow('Doymuş Yağ', '${nutritionFacts.saturatedFat.toStringAsFixed(1)} g'),
        _buildTableRow('Karbonhidrat', '${nutritionFacts.carbohydrates.toStringAsFixed(1)} g'),
        _buildTableRow('Şeker', '${nutritionFacts.sugars.toStringAsFixed(1)} g'),
        _buildTableRow('Protein', '${nutritionFacts.proteins.toStringAsFixed(1)} g'),
        _buildTableRow('Tuz', '${nutritionFacts.salt.toStringAsFixed(1)} g'),
      ],
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }
}