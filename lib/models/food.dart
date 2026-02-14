class Ingredient {
  final String foodId;
  final String foodName; // Salviamo il nome per visualizzazione rapida
  final double grams;

  Ingredient({required this.foodId, required this.foodName, required this.grams});

  Map<String, dynamic> toJson() => {'foodId': foodId, 'foodName': foodName, 'grams': grams};

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(foodId: json['foodId'], foodName: json['foodName'], grams: (json['grams'] as num).toDouble());
}

enum FoodCategory {
  verdura, frutta, carne, pesce, legumi, cereali, latticini, uova, grassi, dolci, bevande, altro
}

class Food {
  final String id;
  final String name;
  final double kcal; // per 100g
  final double proteins;
  final double fats;
  final double saturatedFats;
  final double unsaturatedFats;
  final double carbs;
  final double sugars;
  final double fibers;
  final bool isDish;
  final FoodCategory category;
  final List<Ingredient>? ingredients;

  Food({
    required this.id,
    required this.name,
    required this.kcal,
    required this.proteins,
    required this.fats,
    this.saturatedFats = 0,
    this.unsaturatedFats = 0,
    required this.carbs,
    this.sugars = 0,
    required this.fibers,
    this.isDish = false,
    this.category = FoodCategory.altro,
    this.ingredients,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'proteins': proteins,
        'fats': fats,
        'saturatedFats': saturatedFats,
        'unsaturatedFats': unsaturatedFats,
        'carbs': carbs,
        'sugars': sugars,
        'fibers': fibers,
        'isDish': isDish,
        'category': category.index,
        'ingredients': ingredients?.map((i) => i.toJson()).toList(),
      };

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      kcal: json['kcal'],
      proteins: json['proteins'],
      fats: json['fats'],
      saturatedFats: json['saturatedFats'] ?? 0,
      unsaturatedFats: json['unsaturatedFats'] ?? 0,
      carbs: json['carbs'],
      sugars: json['sugars'] ?? 0,
      fibers: json['fibers'],
      isDish: json['isDish'] ?? false,
      category: json['category'] != null ? FoodCategory.values[json['category']] : FoodCategory.altro,
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List).map((i) => Ingredient.fromJson(i)).toList()
          : null,
    );
  }
}