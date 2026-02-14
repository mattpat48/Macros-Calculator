import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/food.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foods = context.watch<AppState>().foods;

    return Scaffold(
      appBar: AppBar(title: const Text('I Miei Alimenti')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChoiceDialog(context),
        child: const Icon(Icons.add),
      ),
      body: foods.isEmpty
          ? const Center(child: Text('Nessun alimento salvato.'))
          : ListView.builder(
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return ListTile(
                  title: Text(food.name),
                  subtitle: Text('${food.isDish ? "🍲 " : ""}${food.kcal.toStringAsFixed(0)} kcal | P:${food.proteins.toStringAsFixed(1)} G:${food.fats.toStringAsFixed(1)} C:${food.carbs.toStringAsFixed(1)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => context.read<AppState>().deleteFood(food.id),
                  ),
                );
              },
            ),
    );
  }

  void _showChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cosa vuoi aggiungere?'),
        children: [
          SimpleDialogOption(
            child: const Text('Alimento Semplice (es. Pasta, Pollo)'),
            onPressed: () { Navigator.pop(ctx); _showAddSimpleFoodDialog(context); },
          ),
          SimpleDialogOption(
            child: const Text('Piatto Composto (es. Pasta al Pomodoro)'),
            onPressed: () { Navigator.pop(ctx); _showAddDishDialog(context); },
          ),
        ],
      ),
    );
  }

  void _showAddSimpleFoodDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final satFatCtrl = TextEditingController();
    final unsatFatCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final sugarCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    FoodCategory selectedCategory = FoodCategory.altro;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuovo Alimento (per 100g)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome Alimento'))),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _scanAndFetchData(context, nameCtrl, kcalCtrl, protCtrl, fatCtrl, satFatCtrl, unsatFatCtrl, carbCtrl, sugarCtrl, fiberCtrl),
                    ),
                  ],
                ),
                DropdownButton<FoodCategory>(
                  isExpanded: true,
                  value: selectedCategory,
                  items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                TextField(controller: kcalCtrl, decoration: const InputDecoration(labelText: 'Kcal'), keyboardType: TextInputType.number),
                Row(children: [
                  Expanded(child: TextField(controller: protCtrl, decoration: const InputDecoration(labelText: 'Proteine'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: fatCtrl, decoration: const InputDecoration(labelText: 'Grassi Totali'), keyboardType: TextInputType.number)),
                ]),
                Row(children: [
                  Expanded(child: TextField(controller: satFatCtrl, decoration: const InputDecoration(labelText: 'di cui Saturi'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: unsatFatCtrl, decoration: const InputDecoration(labelText: 'di cui Insaturi'), keyboardType: TextInputType.number)),
                ]),
                Row(children: [
                  Expanded(child: TextField(controller: carbCtrl, decoration: const InputDecoration(labelText: 'Carboidrati Totali'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: sugarCtrl, decoration: const InputDecoration(labelText: 'di cui Zuccheri'), keyboardType: TextInputType.number)),
                ]),
                TextField(controller: fiberCtrl, decoration: const InputDecoration(labelText: 'Fibre'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  context.read<AppState>().addFood(Food(
                    id: DateTime.now().toString(),
                    name: nameCtrl.text,
                    kcal: double.tryParse(kcalCtrl.text) ?? 0,
                    proteins: double.tryParse(protCtrl.text) ?? 0,
                    fats: double.tryParse(fatCtrl.text) ?? 0,
                    saturatedFats: double.tryParse(satFatCtrl.text) ?? 0,
                    unsaturatedFats: double.tryParse(unsatFatCtrl.text) ?? 0,
                    carbs: double.tryParse(carbCtrl.text) ?? 0,
                    sugars: double.tryParse(sugarCtrl.text) ?? 0,
                    fibers: double.tryParse(fiberCtrl.text) ?? 0,
                    isDish: false,
                    category: selectedCategory,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanAndFetchData(
    BuildContext context,
    TextEditingController nameCtrl,
    TextEditingController kcalCtrl,
    TextEditingController protCtrl,
    TextEditingController fatCtrl,
    TextEditingController satFatCtrl,
    TextEditingController unsatFatCtrl,
    TextEditingController carbCtrl,
    TextEditingController sugarCtrl,
    TextEditingController fiberCtrl,
  ) async {
    // 1. Apri lo scanner
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
    );

    if (barcode == null) return;

    // 2. Mostra caricamento (opzionale, qui usiamo uno snackbar semplice)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ricerca prodotto in corso...')));

    // 3. Chiama Open Food Facts
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'];

          nameCtrl.text = product['product_name'] ?? '';
          kcalCtrl.text = (nutriments['energy-kcal_100g'] ?? 0).toString();
          protCtrl.text = (nutriments['proteins_100g'] ?? 0).toString();
          fatCtrl.text = (nutriments['fat_100g'] ?? 0).toString();
          satFatCtrl.text = (nutriments['saturated-fat_100g'] ?? 0).toString();
          carbCtrl.text = (nutriments['carbohydrates_100g'] ?? 0).toString();
          sugarCtrl.text = (nutriments['sugars_100g'] ?? 0).toString();
          fiberCtrl.text = (nutriments['fiber_100g'] ?? 0).toString();
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prodotto non trovato.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore di connessione.')));
    }
  }

  void _showAddDishDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final state = context.read<AppState>();
    List<Ingredient> tempIngredients = [];
    
    // Variabili temporanee per l'aggiunta di un ingrediente
    Food? selectedFood;
    final gramsCtrl = TextEditingController();
    FoodCategory selectedCategory = FoodCategory.altro;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuovo Piatto Composto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome Piatto (es. Pasta al sugo)')),
                DropdownButton<FoodCategory>(
                  isExpanded: true,
                  value: selectedCategory,
                  items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 10),
                const Text('Ingredienti:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...tempIngredients.map((ing) => ListTile(
                  dense: true,
                  title: Text(ing.foodName),
                  trailing: Text('${ing.grams.toStringAsFixed(0)}g'),
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => tempIngredients.remove(ing)),
                  ),
                )),
                const Divider(),
                const Text('Aggiungi Ingrediente:'),
                DropdownButton<Food>(
                  isExpanded: true,
                  hint: const Text('Scegli alimento'),
                  value: selectedFood,
                  items: state.foods.where((f) => !f.isDish).map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                  onChanged: (val) => setState(() => selectedFood = val),
                ),
                Row(children: [
                  Expanded(child: TextField(controller: gramsCtrl, decoration: const InputDecoration(labelText: 'Grammi'), keyboardType: TextInputType.number)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      if (selectedFood != null && gramsCtrl.text.isNotEmpty) {
                        setState(() {
                          tempIngredients.add(Ingredient(
                            foodId: selectedFood!.id,
                            foodName: selectedFood!.name,
                            grams: double.tryParse(gramsCtrl.text) ?? 0,
                          ));
                          selectedFood = null;
                          gramsCtrl.clear();
                        });
                      }
                    },
                  )
                ])
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && tempIngredients.isNotEmpty) {
                  // Nota: addDish nel provider dovrà essere aggiornato per accettare la categoria, 
                  // oppure modifichiamo l'oggetto creato internamente. 
                  // Per semplicità qui creiamo l'oggetto manualmente o aggiorniamo il provider.
                  // Aggiorniamo la chiamata al provider passando la categoria se possibile, 
                  // ma dato che addDish calcola tutto, meglio passare la categoria a lui o modificare l'oggetto dopo.
                  // Per ora, modifichiamo addDish nel provider o passiamo la categoria.
                  // Visto che non ho modificato addDish nel provider per accettare category, 
                  // facciamo una piccola forzatura qui o modifichiamo il provider.
                  // Modifichiamo il provider è la via pulita, ma richiede un altro file diff.
                  // Facciamo che addDish prende la categoria opzionale.
                  context.read<AppState>().addDish(nameCtrl.text, tempIngredients, category: selectedCategory);
                  Navigator.pop(context);
                }
              },
              child: const Text('Crea Piatto'),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleScannerScreen extends StatelessWidget {
  const SimpleScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inquadra Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              return; // Torna al primo codice trovato
            }
          }
        },
      ),
    );
  }
}