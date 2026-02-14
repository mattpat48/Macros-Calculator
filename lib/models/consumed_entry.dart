import 'food.dart';

enum MealType { colazione, pranzo, cena, snack, extra }

class ConsumedEntry {
  final String id;
  final Food food;
  final double grams;
  final MealType mealType;
  final DateTime date;

  ConsumedEntry({
    required this.id,
    required this.food,
    required this.grams,
    required this.mealType,
    required this.date,
  });

  double get totalKcal => (food.kcal * grams) / 100;
  double get totalProteins => (food.proteins * grams) / 100;
  double get totalFats => (food.fats * grams) / 100;
  double get totalSaturated => (food.saturatedFats * grams) / 100;
  double get totalUnsaturated => (food.unsaturatedFats * grams) / 100;
  double get totalCarbs => (food.carbs * grams) / 100;
  double get totalSugars => (food.sugars * grams) / 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'food': food.toJson(),
        'grams': grams,
        'mealType': mealType.index,
        'date': date.toIso8601String(),
      };

  factory ConsumedEntry.fromJson(Map<String, dynamic> json) {
    return ConsumedEntry(
      id: json['id'],
      food: Food.fromJson(json['food']),
      grams: json['grams'],
      mealType: MealType.values[json['mealType']],
      date: DateTime.parse(json['date']),
    );
  }
}