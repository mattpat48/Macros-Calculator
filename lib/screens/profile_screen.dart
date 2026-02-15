import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/consumed_entry.dart';
import '../models/food.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profilo & Statistiche', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGoalsCard(context, state),
          const SizedBox(height: 20),
          _buildAdvancedStatistics(context, state),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(BuildContext context, AppState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('I tuoi Obiettivi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                  onPressed: () => _showEditGoalsDialog(context, state),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildGoalRow('Calorie', '${state.targetKcal.toStringAsFixed(0)} kcal', Icons.local_fire_department, Colors.orange),
            _buildGoalRow('Proteine', '${state.targetProteins.toStringAsFixed(0)} g', Icons.fitness_center, Colors.redAccent),
            _buildGoalRow('Carboidrati', '${state.targetCarbs.toStringAsFixed(0)} g', Icons.grain, Colors.blueAccent),
            _buildGoalRow('Grassi', '${state.targetFats.toStringAsFixed(0)} g', Icons.opacity, Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatistics(BuildContext context, AppState state) {
    final logs = state.allLogs;
    if (logs.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('Nessun dato registrato per generare statistiche.'),
      ));
    }

    // 1. Raggruppa i log per giorno
    Map<String, double> dailyCalories = {};
    // Usiamo una mappa per calcolare le proteine totali per categoria (per l'analisi fonti)
    Map<FoodCategory, double> categoryProteins = {};
    double totalProteinsAnalyzed = 0;
    Map<FoodCategory, double> categoryCarbs = {};
    double totalCarbsAnalyzed = 0;
    Map<FoodCategory, double> categoryFats = {};
    double totalFatsAnalyzed = 0;

    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 7));
    final startOfMonth = now.subtract(const Duration(days: 30));

    double sumKcalWeek = 0;
    int daysCountWeek = 0;
    double sumKcalMonth = 0;
    int daysCountMonth = 0;

    // Ordina i log per data per sicurezza
    logs.sort((a, b) => b.date.compareTo(a.date));

    for (var entry in logs) {
      String dayKey = "${entry.date.year}-${entry.date.month}-${entry.date.day}";
      dailyCalories[dayKey] = (dailyCalories[dayKey] ?? 0) + entry.totalKcal;

      // Analisi fonti proteiche (ultimi 30 giorni per rilevanza)
      if (entry.date.isAfter(startOfMonth)) {
        categoryProteins[entry.food.category] = (categoryProteins[entry.food.category] ?? 0) + entry.totalProteins;
        totalProteinsAnalyzed += entry.totalProteins;

        categoryCarbs[entry.food.category] = (categoryCarbs[entry.food.category] ?? 0) + entry.totalCarbs;
        totalCarbsAnalyzed += entry.totalCarbs;

        categoryFats[entry.food.category] = (categoryFats[entry.food.category] ?? 0) + entry.totalFats;
        totalFatsAnalyzed += entry.totalFats;
      }
    }

    // Calcolo medie
    dailyCalories.forEach((key, kcal) {
      // Ricostruisco la data dalla stringa key
      List<String> parts = key.split('-');
      DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      if (date.isAfter(startOfWeek)) {
        sumKcalWeek += kcal;
        daysCountWeek++;
      }
      if (date.isAfter(startOfMonth)) {
        sumKcalMonth += kcal;
        daysCountMonth++;
      }
    });

    double avgWeek = daysCountWeek > 0 ? sumKcalWeek / daysCountWeek : 0;
    double avgMonth = daysCountMonth > 0 ? sumKcalMonth / daysCountMonth : 0;

    // Calcolo Aderenza (Giorni nel range +/- 10% del target)
    int adherentDays = 0;
    int totalDaysChecked = dailyCalories.length;
    double tolerance = 0.10; // 10%
    double minTarget = state.targetKcal * (1 - tolerance);
    double maxTarget = state.targetKcal * (1 + tolerance);

    dailyCalories.forEach((_, kcal) {
      if (kcal >= minTarget && kcal <= maxTarget) {
        adherentDays++;
      }
    });
    double adherencePct = totalDaysChecked > 0 ? (adherentDays / totalDaysChecked) : 0;

    // Ordinamento fonti proteiche
    var sortedProteins = categoryProteins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var sortedCarbs = categoryCarbs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var sortedFats = categoryFats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatBox('Media 7gg', '${avgWeek.toStringAsFixed(0)} kcal', Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatBox('Media 30gg', '${avgMonth.toStringAsFixed(0)} kcal', Colors.purple)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: const Text('Totale Settimanale vs Target'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${sumKcalWeek.toStringAsFixed(0)} / ${(state.targetKcal * 7).toStringAsFixed(0)} kcal'),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (state.targetKcal * 7) > 0 ? (sumKcalWeek / (state.targetKcal * 7)).clamp(0.0, 1.0) : 0,
                  color: sumKcalWeek > (state.targetKcal * 7) ? Colors.red : Colors.green,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: const Text('Aderenza al Piano'),
            subtitle: Text('${(adherencePct * 100).toStringAsFixed(1)}% dei giorni nel range'),
            trailing: CircularProgressIndicator(
              value: adherencePct,
              backgroundColor: Colors.grey[200],
              color: adherencePct > 0.7 ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Fonti Proteiche (ultimi 30gg)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSourceList(sortedProteins, totalProteinsAnalyzed, Colors.redAccent),
        const SizedBox(height: 20),
        const Text('Fonti Carboidrati (ultimi 30gg)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSourceList(sortedCarbs, totalCarbsAnalyzed, Colors.blueAccent),
        const SizedBox(height: 20),
        const Text('Fonti Grassi (ultimi 30gg)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSourceList(sortedFats, totalFatsAnalyzed, Colors.orangeAccent),
      ],
    );
  }

  void _showEditGoalsDialog(BuildContext context, AppState state) {
    final kcalCtrl = TextEditingController(text: state.targetKcal.toString());
    final protCtrl = TextEditingController(text: state.targetProteins.toString());
    final fatCtrl = TextEditingController(text: state.targetFats.toString());
    final carbCtrl = TextEditingController(text: state.targetCarbs.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifica Obiettivi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: kcalCtrl, decoration: const InputDecoration(labelText: 'Calorie (kcal)'), keyboardType: TextInputType.number),
            TextField(controller: protCtrl, decoration: const InputDecoration(labelText: 'Proteine (g)'), keyboardType: TextInputType.number),
            TextField(controller: fatCtrl, decoration: const InputDecoration(labelText: 'Grassi (g)'), keyboardType: TextInputType.number),
            TextField(controller: carbCtrl, decoration: const InputDecoration(labelText: 'Carboidrati (g)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().updateGoals(
                double.tryParse(kcalCtrl.text) ?? 0,
                double.tryParse(protCtrl.text) ?? 0,
                double.tryParse(fatCtrl.text) ?? 0,
                double.tryParse(carbCtrl.text) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)), const SizedBox(height: 5), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))]),
    );
  }

  Widget _buildSourceList(List<MapEntry<FoodCategory, double>> sortedData, double total, Color color) {
    return Column(
      children: sortedData.take(5).map((e) {
        double pct = total > 0 ? e.value / total : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(e.key.name.toUpperCase(), style: const TextStyle(fontSize: 12))),
              Expanded(flex: 5, child: LinearProgressIndicator(value: pct, color: color, backgroundColor: Colors.grey[100])),
              const SizedBox(width: 10),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}