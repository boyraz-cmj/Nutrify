import '../models/product_score.dart';

class ScoringService {
  ProductScore calculateScore(
    Map<String, dynamic> nutritionFacts,
    Map<String, dynamic> nutritionClaims,
  ) {
    // Besin değerlerini normalize et (100g başına)
    final servingSize = _extractNumericValue(nutritionFacts['servingSize']);
    final normalizeFactor = servingSize > 0 ? 100 / servingSize : 1;

    // Negatif puanları hesapla
    double calories =
        _extractNumericValue(nutritionFacts['calories']) * normalizeFactor;
    double energy = calories * 4.184; // kcal'i kJ'a çevir
    int energyPoints = _getEnergyPoints(energy);

    double saturatedFat =
        _extractNumericValue(nutritionFacts['saturatedFat']) * normalizeFactor;
    int saturatedFatPoints = _getSaturatedFatPoints(saturatedFat);

    double sugars =
        _extractNumericValue(nutritionFacts['sugars']) * normalizeFactor;
    int sugarsPoints = _getSugarsPoints(sugars);

    double sodium =
        _extractNumericValue(nutritionFacts['sodium']) * normalizeFactor;
    sodium = sodium / 2.5; // mg salt'ı mg sodium'a çevir
    int sodiumPoints = _getSodiumPoints(sodium);

    // Toplam negatif puan
    int N = energyPoints + saturatedFatPoints + sugarsPoints + sodiumPoints;

    // Pozitif puanları hesapla
    double protein =
        _extractNumericValue(nutritionFacts['protein']) * normalizeFactor;
    int proteinPoints = _getProteinPoints(protein);

    double fiber =
        _extractNumericValue(nutritionFacts['dietaryFiber']) * normalizeFactor;
    int fiberPoints = _getFiberPoints(fiber);

    // Toplam pozitif puan
    int P = proteinPoints + fiberPoints;

    // Final skoru hesapla
    double finalScore;
    if (N >= 11) {
      finalScore = N.toDouble() - P.toDouble();
    } else {
      finalScore = N.toDouble() - P.toDouble();
    }

    // Nutri-Score'u belirle (-15 ile +40 arasındaki puanı A-E'ye çevir)
    String nutriScore;
    if (finalScore <= -1) {
      nutriScore = 'A';
    } else if (finalScore <= 2) {
      nutriScore = 'B';
    } else if (finalScore <= 10) {
      nutriScore = 'C';
    } else if (finalScore <= 18) {
      nutriScore = 'D';
    } else {
      nutriScore = 'E';
    }

    // 0-100 arası puana çevir
    double normalizedScore = ((40 - finalScore) / 55) * 100;
    normalizedScore = normalizedScore.clamp(0, 100);

    return ProductScore(
      totalScore: normalizedScore,
      nutritionScore: normalizedScore,
      allergenScore: 0,
      healthStatus: ProductScore.getHealthStatus(normalizedScore),
      colorCode: ProductScore.getColorCode(normalizedScore),
      nutriscore: nutriScore,
    );
  }

  int _getEnergyPoints(double kj) {
    if (kj <= 335) return 0;
    if (kj <= 670) return 1;
    if (kj <= 1005) return 2;
    if (kj <= 1340) return 3;
    if (kj <= 1675) return 4;
    if (kj <= 2010) return 5;
    if (kj <= 2345) return 6;
    if (kj <= 2680) return 7;
    if (kj <= 3015) return 8;
    if (kj <= 3350) return 9;
    return 10;
  }

  int _getSaturatedFatPoints(double g) {
    if (g <= 1) return 0;
    if (g <= 2) return 1;
    if (g <= 3) return 2;
    if (g <= 4) return 3;
    if (g <= 5) return 4;
    if (g <= 6) return 5;
    if (g <= 7) return 6;
    if (g <= 8) return 7;
    if (g <= 9) return 8;
    if (g <= 10) return 9;
    return 10;
  }

  int _getSugarsPoints(double g) {
    if (g <= 4.5) return 0;
    if (g <= 9) return 1;
    if (g <= 13.5) return 2;
    if (g <= 18) return 3;
    if (g <= 22.5) return 4;
    if (g <= 27) return 5;
    if (g <= 31) return 6;
    if (g <= 36) return 7;
    if (g <= 40) return 8;
    if (g <= 45) return 9;
    return 10;
  }

  int _getSodiumPoints(double mg) {
    if (mg <= 90) return 0;
    if (mg <= 180) return 1;
    if (mg <= 270) return 2;
    if (mg <= 360) return 3;
    if (mg <= 450) return 4;
    if (mg <= 540) return 5;
    if (mg <= 630) return 6;
    if (mg <= 720) return 7;
    if (mg <= 810) return 8;
    if (mg <= 900) return 9;
    return 10;
  }

  int _getProteinPoints(double g) {
    if (g <= 1.6) return 0;
    if (g <= 3.2) return 1;
    if (g <= 4.8) return 2;
    if (g <= 6.4) return 3;
    if (g <= 8.0) return 4;
    return 5;
  }

  int _getFiberPoints(double g) {
    if (g <= 0.9) return 0;
    if (g <= 1.9) return 1;
    if (g <= 2.8) return 2;
    if (g <= 3.7) return 3;
    if (g <= 4.7) return 4;
    return 5;
  }

  double _extractNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final numStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numStr) ?? 0;
    }
    return 0;
  }
}
