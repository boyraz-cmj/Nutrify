import 'package:flutter/material.dart';

class ProductScore {
  final double totalScore;
  final double nutritionScore;
  final double allergenScore;
  final String healthStatus;
  final Color colorCode;
  final String nutriscore;

  const ProductScore({
    required this.totalScore,
    required this.nutritionScore,
    required this.allergenScore,
    required this.healthStatus,
    required this.colorCode,
    required this.nutriscore,
  });

  static String getHealthStatus(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    if (score >= 20) return 'Poor';
    return 'Bad';
  }

  static Color getColorCode(double score) {
    if (score >= 80) return const Color(0xFF1E8F4E); // Dark green
    if (score >= 60) return const Color(0xFF85BB2F); // Light green
    if (score >= 40) return const Color(0xFFFECB02); // Yellow
    if (score >= 20) return const Color(0xFFF39A1A); // Orange
    return const Color(0xFFE63E11); // Red
  }
}
