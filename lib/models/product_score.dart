class ProductScore {
  final double totalScore;
  final double nutritionScore;
  final double allergenScore;
  final String healthStatus;
  final String colorCode;
  final String nutriscore; // A, B, C, D, or E

  const ProductScore({
    required this.totalScore,
    required this.nutritionScore,
    required this.allergenScore,
    required this.healthStatus,
    required this.colorCode,
    required this.nutriscore,
  });

  static String getHealthStatus(double score) {
    if (score <= -1) return 'Mükemmel';
    if (score <= 2) return 'Çok İyi';
    if (score <= 10) return 'İyi';
    if (score <= 18) return 'Orta';
    return 'Kötü';
  }

  static String getColorCode(double score) {
    if (score <= -1) return '#00823F'; // Koyu Yeşil
    if (score <= 2) return '#85BB2F'; // Açık Yeşil
    if (score <= 10) return '#FECB02'; // Sarı
    if (score <= 18) return '#EF8200'; // Turuncu
    return '#E63E11'; // Kırmızı
  }

  static String getNutriScore(double score) {
    if (score <= -1) return 'A';
    if (score <= 2) return 'B';
    if (score <= 10) return 'C';
    if (score <= 18) return 'D';
    return 'E';
  }
}
