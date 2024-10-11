class NutritionFacts {
  final double energy;
  final double fat;
  final double saturatedFat;
  final double carbohydrates;
  final double sugars;
  final double proteins;
  final double salt;

  NutritionFacts({
    required this.energy,
    required this.fat,
    required this.saturatedFat,
    required this.carbohydrates,
    required this.sugars,
    required this.proteins,
    required this.salt,
  });

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    return NutritionFacts(
      energy: json['energy_100g'] ?? 0.0,
      fat: json['fat_100g'] ?? 0.0,
      saturatedFat: json['saturated-fat_100g'] ?? 0.0,
      carbohydrates: json['carbohydrates_100g'] ?? 0.0,
      sugars: json['sugars_100g'] ?? 0.0,
      proteins: json['proteins_100g'] ?? 0.0,
      salt: json['salt_100g'] ?? 0.0,
    );
  }
}