enum AllergenStatus {
  free,     // Yeşil tik - bu maddeden tamamen arındırılmış
  may,      // Sarı soru işareti - bu maddeyi içerebilir
  contains  // Kırmızı X - kesinlikle içeriyor
}

class NutritionClaims {
  final Map<String, String> allergens;
  final Map<String, bool> dietaryInfo;

  NutritionClaims({
    required this.allergens,
    required this.dietaryInfo,
  });

  factory NutritionClaims.fromJson(Map<String, dynamic> json) {
    try {
      return NutritionClaims(
        allergens: (json['allergens'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, value.toString()),
            ) ??
            {},
        dietaryInfo: (json['dietaryInfo'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, value as bool),
            ) ??
            {},
      );
    } catch (e) {
      print('Error parsing NutritionClaims: $e');
      return NutritionClaims(
        allergens: {},
        dietaryInfo: {},
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'allergens': allergens,
        'dietaryInfo': dietaryInfo,
      };

  @override
  String toString() {
    return 'NutritionClaims(allergens: $allergens, dietaryInfo: $dietaryInfo)';
  }
} 