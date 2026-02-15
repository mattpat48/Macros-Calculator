import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/food.dart';
import '../../../models/consumed_entry.dart';

class AppState extends ChangeNotifier {
  List<Food> _foods = [];
  List<ConsumedEntry> _allLogs = [];
  DateTime _selectedDate = DateTime.now();
  
  double targetKcal = 2000;
  double targetProteins = 150;
  double targetFats = 70;
  double targetCarbs = 250;

  List<Food> get foods => _foods;
  
  // Filtra i log per la data selezionata
  List<ConsumedEntry> get allLogs => _allLogs;

  List<ConsumedEntry> get currentLog => _allLogs.where((e) => 
    e.date.year == _selectedDate.year && 
    e.date.month == _selectedDate.month && 
    e.date.day == _selectedDate.day
  ).toList();

  DateTime get selectedDate => _selectedDate;

  AppState() {
    _loadData();
  }

  double get currentKcal => currentLog.fold(0, (sum, item) => sum + item.totalKcal);
  double get currentProteins => currentLog.fold(0, (sum, item) => sum + item.totalProteins);
  double get currentFats => currentLog.fold(0, (sum, item) => sum + item.totalFats);
  double get currentCarbs => currentLog.fold(0, (sum, item) => sum + item.totalCarbs);

  void changeDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void addFood(Food food) {
    _foods.add(food);
    _saveData();
    notifyListeners();
  }

  // Metodo speciale per creare un piatto composto
  void addDish(String name, List<Ingredient> ingredients, {FoodCategory category = FoodCategory.altro}) {
    double totalGrams = 0;
    double totalKcal = 0;
    double totalProt = 0;
    double totalFats = 0;
    double totalSat = 0;
    double totalUnsat = 0;
    double totalCarbs = 0;
    double totalSugars = 0;
    double totalFibers = 0;

    for (var ing in ingredients) {
      final food = _foods.firstWhere((f) => f.id == ing.foodId, orElse: () => _foods.first);
      double ratio = ing.grams / 100;
      totalGrams += ing.grams;
      totalKcal += food.kcal * ratio;
      totalProt += food.proteins * ratio;
      totalFats += food.fats * ratio;
      totalSat += food.saturatedFats * ratio;
      totalUnsat += food.unsaturatedFats * ratio;
      totalCarbs += food.carbs * ratio;
      totalSugars += food.sugars * ratio;
      totalFibers += food.fibers * ratio;
    }

    // Normalizza per 100g
    double factor = totalGrams > 0 ? 100 / totalGrams : 0;

    addFood(Food(
      id: DateTime.now().toString(),
      name: name,
      kcal: totalKcal * factor,
      proteins: totalProt * factor,
      fats: totalFats * factor,
      saturatedFats: totalSat * factor,
      unsaturatedFats: totalUnsat * factor,
      carbs: totalCarbs * factor,
      sugars: totalSugars * factor,
      fibers: totalFibers * factor,
      isDish: true,
      category: category,
      ingredients: ingredients,
    ));
  }

  void deleteFood(String id) {
    _foods.removeWhere((f) => f.id == id);
    _saveData();
    notifyListeners();
  }

  void addEntry(ConsumedEntry entry) {
    _allLogs.add(entry);
    _saveData();
    notifyListeners();
  }

  void removeEntry(String id) {
    _allLogs.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  void updateGoals(double kcal, double prot, double fats, double carbs) {
    targetKcal = kcal;
    targetProteins = prot;
    targetFats = fats;
    targetCarbs = carbs;
    _saveData();
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String foodsJson = jsonEncode(_foods.map((f) => f.toJson()).toList());
    await prefs.setString('foods', foodsJson);

    final String logJson = jsonEncode(_allLogs.map((e) => e.toJson()).toList());
    await prefs.setString('todayLog', logJson);

    await prefs.setDouble('targetKcal', targetKcal);
    await prefs.setDouble('targetProteins', targetProteins);
    await prefs.setDouble('targetFats', targetFats);
    await prefs.setDouble('targetCarbs', targetCarbs);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final String? foodsJson = prefs.getString('foods');
    if (foodsJson != null) {
      final List<dynamic> decoded = jsonDecode(foodsJson);
      _foods = decoded.map((json) => Food.fromJson(json)).toList();
    }

    final String? logJson = prefs.getString('todayLog');
    if (logJson != null) {
      final List<dynamic> decoded = jsonDecode(logJson);
      _allLogs = decoded.map((json) => ConsumedEntry.fromJson(json)).toList();
    }

    targetKcal = prefs.getDouble('targetKcal') ?? 2000;
    targetProteins = prefs.getDouble('targetProteins') ?? 150;
    targetFats = prefs.getDouble('targetFats') ?? 70;
    targetCarbs = prefs.getDouble('targetCarbs') ?? 250;

    notifyListeners();
  }
}