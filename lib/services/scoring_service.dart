import '../models/product_score.dart';

class ScoringService {
  ProductScore calculateScore(Map<String, dynamic> nutritionFacts,
      Map<String, dynamic>? nutritionClaims) {
    // Calculate base nutrition score
    double nutritionScore = _calculateNutritionScore(nutritionFacts);

    // Calculate allergen score (keeping this for additional information)
    double allergenScore = _calculateAllergenScore(nutritionClaims);

    // Calculate total score (using Nutri-Score system)
    double totalScore = nutritionScore;

    return ProductScore(
      totalScore: totalScore,
      nutritionScore: nutritionScore,
      allergenScore: allergenScore,
      healthStatus: ProductScore.getHealthStatus(totalScore),
      colorCode: ProductScore.getColorCode(totalScore),
      nutriscore: ProductScore.getNutriScore(totalScore),
    );
  }

  double _calculateNutritionScore(Map<String, dynamic> nutritionFacts) {
    // Normalize to 100g
    double servingSize = _extractServingSize(nutritionFacts['servingSize']);
    double normalizeFactor = 100 / servingSize;

    // Extract and normalize values to 100g
    double calories =
        _extractNumericValue(nutritionFacts['calories']) * normalizeFactor;
    double energy = calories * 4.184; // Convert kcal to kJ
    double sugars =
        _extractNumericValue(nutritionFacts['sugars']) * normalizeFactor;
    double saturatedFat =
        _extractNumericValue(nutritionFacts['saturatedFat']) * normalizeFactor;
    double sodium =
        _extractNumericValue(nutritionFacts['sodium']) * normalizeFactor;
    double protein =
        _extractNumericValue(nutritionFacts['protein']) * normalizeFactor;
    double fiber =
        _extractNumericValue(nutritionFacts['dietaryFiber']) * normalizeFactor;

    // Calculate N points (negative components)
    int energyPoints = _getEnergyPoints(energy);
    int sugarsPoints = _getSugarsPoints(sugars);
    int saturatedFatPoints = _getSaturatedFatPoints(saturatedFat);
    int sodiumPoints = _getSodiumPoints(sodium);

    int N = energyPoints + sugarsPoints + saturatedFatPoints + sodiumPoints;

    // Calculate P points (positive components)
    int proteinPoints = _getProteinPoints(protein);
    int fiberPoints = _getFiberPoints(fiber);

    int P = proteinPoints + fiberPoints;

    // Calculate final score
    if (N >= 11) {
      // Only consider fiber points when N >= 11
      return (N - fiberPoints).toDouble();
    }

    return (N - P).toDouble();
  }

  int _getEnergyPoints(double kJ) {
    if (kJ <= 335) return 0;
    if (kJ <= 670) return 1;
    if (kJ <= 1005) return 2;
    if (kJ <= 1340) return 3;
    if (kJ <= 1675) return 4;
    if (kJ <= 2010) return 5;
    if (kJ <= 2345) return 6;
    if (kJ <= 2680) return 7;
    if (kJ <= 3015) return 8;
    if (kJ <= 3350) return 9;
    return 10;
  }

  int _getSugarsPoints(double sugars) {
    if (sugars <= 4.5) return 0;
    if (sugars <= 9) return 1;
    if (sugars <= 13.5) return 2;
    if (sugars <= 18) return 3;
    if (sugars <= 22.5) return 4;
    if (sugars <= 27) return 5;
    if (sugars <= 31) return 6;
    if (sugars <= 36) return 7;
    if (sugars <= 40) return 8;
    if (sugars <= 45) return 9;
    return 10;
  }

  int _getSaturatedFatPoints(double saturatedFat) {
    if (saturatedFat <= 1) return 0;
    if (saturatedFat <= 2) return 1;
    if (saturatedFat <= 3) return 2;
    if (saturatedFat <= 4) return 3;
    if (saturatedFat <= 5) return 4;
    if (saturatedFat <= 6) return 5;
    if (saturatedFat <= 7) return 6;
    if (saturatedFat <= 8) return 7;
    if (saturatedFat <= 9) return 8;
    if (saturatedFat <= 10) return 9;
    return 10;
  }

  int _getSodiumPoints(double sodium) {
    sodium = sodium / 2.5; // Convert from mg salt to mg sodium
    if (sodium <= 90) return 0;
    if (sodium <= 180) return 1;
    if (sodium <= 270) return 2;
    if (sodium <= 360) return 3;
    if (sodium <= 450) return 4;
    if (sodium <= 540) return 5;
    if (sodium <= 630) return 6;
    if (sodium <= 720) return 7;
    if (sodium <= 810) return 8;
    if (sodium <= 900) return 9;
    return 10;
  }

  int _getProteinPoints(double protein) {
    if (protein <= 1.6) return 0;
    if (protein <= 3.2) return 1;
    if (protein <= 4.8) return 2;
    if (protein <= 6.4) return 3;
    if (protein <= 8.0) return 4;
    if (protein > 8.0) return 5;
    return 0;
  }

  int _getFiberPoints(double fiber) {
    if (fiber <= 0.9) return 0;
    if (fiber <= 1.9) return 1;
    if (fiber <= 2.8) return 2;
    if (fiber <= 3.7) return 3;
    if (fiber <= 4.7) return 4;
    return 5;
  }

  double _calculateAllergenScore(Map<String, dynamic>? nutritionClaims) {
    if (nutritionClaims == null) return 0;
    double score = 0;
    final maxScore = 30.0;

    // Allergen score (20 points)
    final allergens =
        nutritionClaims['allergens'] as Map<String, dynamic>? ?? {};
    if (allergens.isEmpty) {
      score += 20; // No allergens
    } else {
      int freeCount = allergens.values
          .where((value) => value.toString().toLowerCase().contains('free'))
          .length;
      int mayCount = allergens.values
          .where((value) => value.toString().toLowerCase().contains('may'))
          .length;
      int containsCount = allergens.length - freeCount - mayCount;

      score += (freeCount / allergens.length) * 20;
      score -= (mayCount / allergens.length) * 5;
      score -= (containsCount / allergens.length) * 10;
    }

    // Dietary score (10 points)
    final dietaryInfo =
        nutritionClaims['dietaryInfo'] as Map<String, dynamic>? ?? {};
    if (dietaryInfo.isNotEmpty) {
      int suitableCount =
          dietaryInfo.values.where((value) => value == true).length;
      score += (suitableCount / dietaryInfo.length) * 10;
    } else {
      score += 5; // Default score
    }

    return score.clamp(0, 30);
  }

  double _extractServingSize(dynamic servingSize) {
    if (servingSize == null) return 100;
    if (servingSize is num) return servingSize.toDouble();

    if (servingSize is String) {
      final match = RegExp(r'(\d+\.?\d*)\s*(g|ml|kg|l)', caseSensitive: false)
          .firstMatch(servingSize);

      if (match != null) {
        double? value = double.tryParse(match.group(1)!);
        String? unit = match.group(2)?.toLowerCase();

        if (value != null && unit != null) {
          switch (unit) {
            case 'kg':
              return value * 1000;
            case 'l':
              return value * 1000;
            case 'ml':
              return value; // Treating ml as g (approximate)
            case 'g':
              return value;
            default:
              return 100;
          }
        }
      }
    }

    return 100; // Default value
  }

  double _extractNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(value);
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 0;
      }
    }
    return 0;
  }
}
