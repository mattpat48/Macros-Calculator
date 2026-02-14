import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/food.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo & Statistiche')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGoalsCard(context, state),
          const SizedBox(height: 20),
          const Text('Statistiche di Oggi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Ripartizione calorie per categoria', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          _buildStatistics(state),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(BuildContext context, AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('I tuoi Obiettivi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditGoalsDialog(context, state),
                )
              ],
            ),
            const Divider(),
            Text('Calorie: ${state.targetKcal.toStringAsFixed(0)} kcal'),
            Text('Proteine: ${state.targetProteins.toStringAsFixed(0)} g'),
            Text('Grassi: ${state.targetFats.toStringAsFixed(0)} g'),
            Text('Carboidrati: ${state.targetCarbs.toStringAsFixed(0)} g'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(AppState state) {
    if (state.currentLog.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('Nessun dato per la data selezionata.'),
      ));
    }

    // Calcola le calorie totali per categoria
    Map<FoodCategory, double> categoryKcal = {};
    double totalKcal = 0;

    for (var entry in state.currentLog) {
      double kcal = entry.totalKcal;
      categoryKcal[entry.food.category] = (categoryKcal[entry.food.category] ?? 0) + kcal;
      totalKcal += kcal;
    }

    if (totalKcal == 0) return const Text('Totale calorie: 0');

    // Ordina per valore decrescente
    var sortedEntries = categoryKcal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((e) {
        double percentage = e.value / totalKcal;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${(percentage * 100).toStringAsFixed(1)}% (${e.value.toStringAsFixed(0)} kcal)'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
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
}