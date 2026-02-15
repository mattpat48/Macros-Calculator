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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('I Miei Alimenti', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChoiceSheet(context),
        label: const Text('Nuovo'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: foods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Nessun alimento salvato.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Aggiungine uno col tasto +', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 10, left: 10, right: 10),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: food.isDish ? Colors.orange[100] : Colors.blue[100],
                      child: Icon(
                        food.isDish ? Icons.soup_kitchen : Icons.fastfood,
                        color: food.isDish ? Colors.orange : Colors.blue,
                      ),
                    ),
                    title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${food.kcal.toStringAsFixed(0)} kcal\nP: ${food.proteins.toStringAsFixed(1)}  G: ${food.fats.toStringAsFixed(1)}  C: ${food.carbs.toStringAsFixed(1)}',
                        style: TextStyle(color: Colors.grey[700], height: 1.3),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, food),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, Food food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Alimento'),
        content: Text('Vuoi davvero eliminare "${food.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteFood(food.id);
              Navigator.pop(ctx);
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cosa vuoi aggiungere?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.egg_alt, color: Colors.blue, size: 30),
              title: const Text('Alimento Semplice'),
              subtitle: const Text('Es. Pollo, Riso, Mela'),
              onTap: () { Navigator.pop(ctx); _showAddSimpleFoodSheet(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dinner_dining, color: Colors.orange, size: 30),
              title: const Text('Piatto Composto'),
              subtitle: const Text('Es. Pasta al Pomodoro, Insalatona'),
              onTap: () { Navigator.pop(ctx); _showAddDishSheet(context); },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddSimpleFoodSheet(BuildContext context, {Food? toAdd}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => AddSimpleFoodSheet(toAdd: toAdd),
    );
  }

  void _showAddDishSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const AddDishSheet(),
    );
  }
}

class AddSimpleFoodSheet extends StatefulWidget {
  final Food? toAdd;

  const AddSimpleFoodSheet({super.key, this.toAdd});

  @override
  State<AddSimpleFoodSheet> createState() => _AddSimpleFoodSheetState();
}

class _AddSimpleFoodSheetState extends State<AddSimpleFoodSheet> {
  final _formKey = GlobalKey<FormState>();
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.toAdd != null) {
      nameCtrl.text = widget.toAdd!.name;
      kcalCtrl.text = widget.toAdd!.kcal.toStringAsFixed(0);
      protCtrl.text = widget.toAdd!.proteins.toStringAsFixed(1);
      fatCtrl.text = widget.toAdd!.fats.toStringAsFixed(1);
      satFatCtrl.text = widget.toAdd!.saturatedFats.toStringAsFixed(1);
      unsatFatCtrl.text = widget.toAdd!.unsaturatedFats.toStringAsFixed(1);
      carbCtrl.text = widget.toAdd!.carbs.toStringAsFixed(1);
      sugarCtrl.text = widget.toAdd!.sugars.toStringAsFixed(1);
      fiberCtrl.text = widget.toAdd!.fibers.toStringAsFixed(1);
      selectedCategory = widget.toAdd!.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nuovo Alimento (100g)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nome Alimento',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.label),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                                onPressed: _scanBarcode,
                                tooltip: 'Scansiona Barcode',
                              ),
                            ),
                            validator: (value) => value!.isEmpty ? 'Inserisci un nome' : null,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<FoodCategory>(
                            value: selectedCategory,
                            decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                            items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                            onChanged: (v) => setState(() => selectedCategory = v!),
                          ),
                          const SizedBox(height: 15),
                          _buildNumField(kcalCtrl, 'Kcal', Icons.local_fire_department),
                          const SizedBox(height: 15),
                          Row(children: [
                            Expanded(child: _buildNumField(protCtrl, 'Proteine', Icons.fitness_center)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildNumField(fatCtrl, 'Grassi', Icons.opacity)),
                          ]),
                          const SizedBox(height: 15),
                          Row(children: [
                            Expanded(child: _buildNumField(satFatCtrl, 'Saturi', null)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildNumField(unsatFatCtrl, 'Insaturi', null)),
                          ]),
                          const SizedBox(height: 15),
                          Row(children: [
                            Expanded(child: _buildNumField(carbCtrl, 'Carboidrati', Icons.grain)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildNumField(sugarCtrl, 'Zuccheri', null)),
                          ]),
                          const SizedBox(height: 15),
                          _buildNumField(fiberCtrl, 'Fibre', Icons.grass),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: _saveFood,
                              child: const Text('SALVA ALIMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumField(TextEditingController ctrl, String label, IconData? icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        isDense: true,
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
    );

    if (barcode == null) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutriscore_data,nutriments');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final nutriments = product['nutriments'] as Map<String, dynamic>?;

          if (mounted) {
            setState(() {
              nameCtrl.text = product['product_name'] ?? 'Alimento Scansionato';
              
              if (nutriments != null) {
                kcalCtrl.text = (nutriments['energy-kcal_100g'] ?? 0).toString();
                protCtrl.text = (nutriments['proteins_100g'] ?? 0).toString();
                fatCtrl.text = (nutriments['fat_100g'] ?? 0).toString();
                satFatCtrl.text = (nutriments['saturated-fat_100g'] ?? 0).toString();
                carbCtrl.text = (nutriments['carbohydrates_100g'] ?? 0).toString();
                sugarCtrl.text = (nutriments['sugars_100g'] ?? 0).toString();
                fiberCtrl.text = (nutriments['fiber_100g'] ?? 0).toString();
                
                // Calcolo approssimativo insaturi se non presenti
                double fat = double.tryParse(fatCtrl.text) ?? 0;
                double sat = double.tryParse(satFatCtrl.text) ?? 0;
                unsatFatCtrl.text = (fat - sat).clamp(0, fat).toStringAsFixed(1);
              }
            });
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prodotto non trovato.')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore del server.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante la scansione.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveFood() {
    if (_formKey.currentState!.validate()) {
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
  }
}

class AddDishSheet extends StatefulWidget {
  const AddDishSheet({super.key});

  @override
  State<AddDishSheet> createState() => _AddDishSheetState();
}

class _AddDishSheetState extends State<AddDishSheet> {
  final nameCtrl = TextEditingController();
  List<Ingredient> tempIngredients = [];
  Food? selectedFood;
  final gramsCtrl = TextEditingController();
  FoodCategory selectedCategory = FoodCategory.altro;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nuovo Piatto Composto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome Piatto (es. Pasta al sugo)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<FoodCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                      items: FoodCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingredienti:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (tempIngredients.isEmpty)
                            const Padding(padding: EdgeInsets.all(8.0), child: Text('Nessun ingrediente aggiunto.', style: TextStyle(color: Colors.grey))),
                          ...tempIngredients.map((ing) => ListTile(
                            dense: true,
                            title: Text(ing.foodName),
                            trailing: Text('${ing.grams.toStringAsFixed(0)}g'),
                            leading: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => setState(() => tempIngredients.remove(ing)),
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Aggiungi Ingrediente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<Food>(
                            isExpanded: true,
                            hint: const Text('Scegli alimento'),
                            value: selectedFood,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                            items: state.foods.where((f) => !f.isDish).map((f) => DropdownMenuItem(value: f, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => selectedFood = val),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: gramsCtrl,
                            decoration: const InputDecoration(labelText: 'Grammi', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
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
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () {
                          if (nameCtrl.text.isNotEmpty && tempIngredients.isNotEmpty) {
                            context.read<AppState>().addDish(nameCtrl.text, tempIngredients, category: selectedCategory);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('CREA PIATTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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