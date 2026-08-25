import 'package:flutter/material.dart';
import 'services/database_helper.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense['title']);
    _amountController = TextEditingController(text: widget.expense['amount'].toString());
    _noteController = TextEditingController(text: widget.expense['note'] ?? '');
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategories();

    // Retrouver l'ID de la catégorie actuelle de la dépense
    // (Dans getExpenses, on récupère le nom de la catégorie, donc on cherche l'ID correspondant)
    int? matchedCategoryId;
    for (var cat in categories) {
      if (cat['name'] == widget.expense['category_name']) {
        matchedCategoryId = cat['id'];
        break;
      }
    }

    setState(() {
      _categories = categories;
      _selectedCategoryId = matchedCategoryId ?? (categories.isNotEmpty ? categories.first['id'] : null);
      _isLoading = false;
    });
  }

  Future<void> _updateExpense() async {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

      await DatabaseHelper.instance.updateExpense(widget.expense['id'], {
        'title': _titleController.text,
        'amount': amount,
        'note': _noteController.text,
        'category_id': _selectedCategoryId,
      });

      if (mounted) {
        Navigator.pop(context, true); // Revient en arrière et demande un refresh
      }
    }
  }

  Future<void> _deleteExpense() async {
    await DatabaseHelper.instance.deleteExpense(widget.expense['id']);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF5B9EE1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la dépense', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              // Boîte de dialogue de confirmation de suppression
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer la dépense'),
                  content: const Text('Êtes-vous sûr de vouloir supprimer cette dépense ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Ferme la boîte de dialogue
                        _deleteExpense(); // Supprime et quitte l'écran
                      },
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veu entrer un titre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant (€)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Veu entrer un montant';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'] as int,
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Note / Descriptif',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _updateExpense,
                child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}