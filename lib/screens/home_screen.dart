import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/food.dart';
import '../../../models/consumed_entry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Diario: ${state.selectedDate.day}/${state.selectedDate.month}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) context.read<AppState>().changeDate(picked);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        label: const Text('Aggiungi Pasto'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressCard(context, 'Calorie', state.currentKcal, state.targetKcal, Colors.orange, null),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildProgressCard(context, 'Proteine', state.currentProteins, state.targetProteins, Colors.red, null)),
              const SizedBox(width: 10),
              Expanded(child: _buildProgressCard(context, 'Carbo', state.currentCarbs, state.targetCarbs, Colors.blue, 'Zucch: ${state.currentLog.fold(0.0, (s, e) => s + e.totalSugars).toStringAsFixed(0)}g')),
              const SizedBox(width: 10),
              Expanded(child: _buildProgressCard(context, 'Grassi', state.currentFats, state.targetFats, Colors.yellow[700]!, 'Sat: ${state.currentLog.fold(0.0, (s, e) => s + e.totalSaturated).toStringAsFixed(0)}g')),
            ],
          ),
          const SizedBox(height: 20),
          Text('Pasti del ${state.selectedDate.day}/${state.selectedDate.month}:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (state.currentLog.isEmpty)
            const Center(child: Text('Nessun pasto registrato in questa data.', style: TextStyle(color: Colors.grey))),
          ...state.currentLog.map((entry) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(entry.mealType.name[0].toUpperCase())),
              title: Text(entry.food.name),
              subtitle: Text('${entry.grams.toStringAsFixed(0)}g - ${entry.mealType.name}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => context.read<AppState>().removeEntry(entry.id),
              ),
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String label, double current, double target, Color color, String? subLabel) {
    double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    double remaining = target - current;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            LinearProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.2)),
            const SizedBox(height: 5),
            Text('${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}'),
            Text(
              remaining > 0 ? 'Mancano ${remaining.toStringAsFixed(0)}' : 'Sforato di ${(-remaining).toStringAsFixed(0)}!',
              style: TextStyle(fontSize: 10, color: remaining < 0 ? Colors.red : Colors.grey),
            ),
            if (subLabel != null)
              Text(subLabel, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final state = context.read<AppState>();
    if (state.foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aggiungi prima degli alimenti nella lista!')));
      return;
    }

    Food? selectedFood;
    MealType selectedMeal = MealType.colazione;
    final gramsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registra Pasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Food>(
                isExpanded: true,
                hint: const Text('Seleziona Alimento'),
                value: selectedFood,
                items: state.foods.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                onChanged: (val) => setState(() => selectedFood = val),
              ),
              TextField(
                controller: gramsController,
                decoration: const InputDecoration(labelText: 'Grammi'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<MealType>(
                isExpanded: true,
                value: selectedMeal,
                items: MealType.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (val) => setState(() => selectedMeal = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                if (selectedFood != null && gramsController.text.isNotEmpty) {
                  context.read<AppState>().addEntry(ConsumedEntry(
                    id: DateTime.now().toString(),
                    food: selectedFood!,
                    grams: double.tryParse(gramsController.text) ?? 0,
                    mealType: selectedMeal,
                    date: state.selectedDate, // Usa la data selezionata nel calendario
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}