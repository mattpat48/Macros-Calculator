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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diario Alimentare',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              '${state.selectedDate.day}/${state.selectedDate.month}/${state.selectedDate.year}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.blueAccent),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) context.read<AppState>().changeDate(picked);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context),
        label: const Text('Aggiungi Pasto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildSummaryCard(state),
          const SizedBox(height: 20),
          if (state.currentLog.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.no_meals_outlined, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    Text('Nessun pasto registrato oggi.', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ...MealType.values.expand((type) {
            final entries = state.currentLog.where((e) => e.mealType == type).toList();
            if (entries.isEmpty) return <Widget>[];

            final double mealKcal = entries.fold(0, (sum, e) => sum + e.totalKcal);
            final double mealProteins = entries.fold(0, (sum, e) => sum + e.totalProteins);
            final double mealCarbs = entries.fold(0, (sum, e) => sum + e.totalCarbs);
            final double mealFats = entries.fold(0, (sum, e) => sum + e.totalFats);
            final double mealFibers = entries.fold(0, (sum, e) => sum + e.totalFibers);

            return [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  shape: const Border(), // Rimuove i bordi interni dell'ExpansionTile
                  leading: CircleAvatar(
                    backgroundColor: _getMealColor(type).withOpacity(0.2),
                    child: Icon(_getMealIcon(type), color: _getMealColor(type)),
                  ),
                  title: Text(type.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('${mealKcal.toStringAsFixed(0)} kcal, ${mealProteins.toStringAsFixed(1)}g P, ${mealCarbs.toStringAsFixed(1)}g C, ${mealFats.toStringAsFixed(1)}g F, ${mealFibers.toStringAsFixed(1)}g FIB'),
                  children: entries.map((entry) => ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: Text(entry.food.name),
                    subtitle: Text('${entry.grams.toStringAsFixed(0)}g  •  ${entry.totalKcal.toStringAsFixed(0)} kcal, ${entry.totalProteins.toStringAsFixed(1)} g P, ${entry.totalCarbs.toStringAsFixed(1)}g C, ${entry.totalFats.toStringAsFixed(1)}g F'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => context.read<AppState>().removeEntry(entry.id),
                    ),
                  )).toList(),
                ),
              )
            ];
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riepilogo Calorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${state.currentKcal.toStringAsFixed(0)} / ${state.targetKcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: state.targetKcal > 0 ? (state.currentKcal / state.targetKcal).clamp(0.0, 1.0) : 0,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: state.currentKcal > state.targetKcal ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroItem('Proteine', state.currentProteins, state.targetProteins, Colors.redAccent),
                _buildMacroItem('Carboidrati', state.currentCarbs, state.targetCarbs, Colors.blueAccent),
                _buildMacroItem('Grassi', state.currentFats, state.targetFats, Colors.orangeAccent),
                _buildMacroItem('Fibre', state.currentFibers, state.targetFibers, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, double current, double target, Color color) {
    double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 5),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color.withOpacity(0.1),
                strokeWidth: 6,
              ),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Text('${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddEntrySheet(BuildContext context) {
    final state = context.read<AppState>();
    if (state.foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aggiungi prima degli alimenti nella lista!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const AddMealSheet(),
    );
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.colazione: return Colors.orange;
      case MealType.pranzo: return Colors.blue;
      case MealType.cena: return Colors.indigo;
      case MealType.snack: return Colors.green;
      case MealType.extra: return Colors.purple;
    }
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.colazione: return Icons.wb_sunny_outlined;
      case MealType.pranzo: return Icons.restaurant;
      case MealType.cena: return Icons.nights_stay_outlined;
      case MealType.snack: return Icons.apple_outlined;
      case MealType.extra: return Icons.icecream_outlined;
    }
  }
}

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({super.key});

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  MealType selectedMeal = MealType.colazione;
  List<Map<String, dynamic>> entryRows = [
    {'food': null, 'gramsCtrl': TextEditingController()}
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sortedFoods = List<Food>.from(state.foods)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Componi Pasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    DropdownButtonFormField<MealType>(
                      value: selectedMeal,
                      decoration: const InputDecoration(labelText: 'Tipo di Pasto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                      items: MealType.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                      onChanged: (val) => setState(() => selectedMeal = val!),
                    ),
                    const SizedBox(height: 20),
                    const Text('Ingredienti:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ...entryRows.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var row = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<Food>(
                                isExpanded: true,
                                hint: const Text('Alimento'),
                                value: row['food'],
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                                items: sortedFoods.map((f) => DropdownMenuItem(value: f, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) => setState(() {
                                  row['food'] = val;
                                  if (val != null && val.isDish) {
                                    final totalGrams = val.ingredients?.fold(0.0, (sum, e) => sum + e.grams) ?? 0;
                                    row['gramsCtrl'].text = totalGrams.toStringAsFixed(0);
                                  } else {
                                    row['gramsCtrl'].clear();
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: row['gramsCtrl'],
                                decoration: const InputDecoration(labelText: 'g', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                                keyboardType: TextInputType.number,
                                enabled: row['food'] == null || !(row['food'] as Food).isDish,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                if (entryRows.length > 1) {
                                  setState(() => entryRows.removeAt(idx));
                                }
                                else {
                                  setState(() { row['food'] = null; row['gramsCtrl'].clear(); });
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Aggiungi altro ingrediente'),
                      onPressed: () => setState(() => entryRows.add({'food': null, 'gramsCtrl': TextEditingController()})),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () {
                          int count = 0;
                          for (var row in entryRows) {
                            if (row['food'] != null && row['gramsCtrl'].text.isNotEmpty) {
                              context.read<AppState>().addEntry(ConsumedEntry(
                                id: '${DateTime.now().millisecondsSinceEpoch}_$count',
                                food: row['food'],
                                grams: double.tryParse(row['gramsCtrl'].text) ?? 0,
                                mealType: selectedMeal,
                                date: state.selectedDate,
                              ));
                              count++;
                            }
                          }
                          if (count > 0) Navigator.pop(context);
                        },
                        child: const Text('SALVA PASTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}