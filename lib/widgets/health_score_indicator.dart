import 'package:flutter/material.dart';
import '../models/product_score.dart';

class HealthScoreIndicator extends StatelessWidget {
  final ProductScore score;
  final double size;

  const HealthScoreIndicator({
    super.key,
    required this.score,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(int.parse(score.colorCode.replaceAll('#', '0xFF'))),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse(score.colorCode.replaceAll('#', '0xFF')))
                .withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.nutriscore,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.healthStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
