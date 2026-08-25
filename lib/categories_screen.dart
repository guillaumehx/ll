import 'package:flutter/material.dart';
import 'services/database_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  // Boîte de dialogue pour ajouter une catégorie (avec nom + choix d'icône)
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIconKey = 'shopping_cart'; // Icône par défaut
    const primaryBlue = Color(0xFF5B9EE1);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouvelle catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la catégorie',
                    hintText: 'ex: Hi-Tech',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choisir une icône :', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),

                // Grille de sélection d'icônes
                SizedBox(
                  width: double.maxFinite,
                  height: 160,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: availableCategoryIcons.length,
                    itemBuilder: (context, index) {
                      String key = availableCategoryIcons.keys.elementAt(index);
                      IconData iconData = availableCategoryIcons[key]!;
                      bool isSelected = key == selectedIconKey;

                      return GestureDetector(
                        onTap: () => setStateDialog(() => selectedIconKey = key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue.withOpacity(0.15) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryBlue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            iconData,
                            color: isSelected ? primaryBlue : const Color(0xFF64748B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await DatabaseHelper.instance.insertCategory(nameController.text, selectedIconKey);
                  Navigator.pop(context);
                  _loadCategories();
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  // Boîte de dialogue pour modifier une catégorie (nom + icône)
  void _showEditCategoryDialog(int categoryId, String currentName, String? currentIcon) {
    final nameController = TextEditingController(text: currentName);
    String selectedIconKey = currentIcon ?? 'shopping_cart';
    const primaryBlue = Color(0xFF5B9EE1);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier la catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nouveau nom',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Modifier l\'icône :', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.maxFinite,
                  height: 160,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: availableCategoryIcons.length,
                    itemBuilder: (context, index) {
                      String key = availableCategoryIcons.keys.elementAt(index);
                      IconData iconData = availableCategoryIcons[key]!;
                      bool isSelected = key == selectedIconKey;

                      return GestureDetector(
                        onTap: () => setStateDialog(() => selectedIconKey = key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue.withOpacity(0.15) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryBlue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            iconData,
                            color: isSelected ? primaryBlue : const Color(0xFF64748B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await DatabaseHelper.instance.updateCategory(categoryId, nameController.text, selectedIconKey);
                  Navigator.pop(context);
                  _loadCategories();
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // Boîte de dialogue pour gérer la migration en bulk avant suppression
  void _showMigrationDialog(int oldCategoryId, String oldCategoryName) async {
    int? selectedNewCategoryId;
    final otherCategories = _categories.where((c) => c['id'] != oldCategoryId).toList();

    if (otherCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer la dernière catégorie restante.')),
      );
      return;
    }

    selectedNewCategoryId = otherCategories.first['id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Supprimer "$oldCategoryName"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Où voulez-vous migrer les dépenses associées à cette catégorie ?'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedNewCategoryId,
                items: otherCategories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'] as int,
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setStateDialog(() {
                    selectedNewCategoryId = val;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedNewCategoryId != null) {
                  await DatabaseHelper.instance.migrateExpensesCategory(oldCategoryId, selectedNewCategoryId!);
                  await DatabaseHelper.instance.deleteCategory(oldCategoryId);

                  if (mounted) {
                    Navigator.pop(context);
                    _loadCategories();
                  }
                }
              },
              child: const Text('Migrer et Supprimer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF5B9EE1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestion des catégories', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Affichage dynamique de l'icône de la catégorie
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getCategoryIcon(cat['icon']),
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    cat['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: primaryBlue),
                      onPressed: () => _showEditCategoryDialog(cat['id'], cat['name'], cat['icon']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _showMigrationDialog(cat['id'], cat['name']),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddCategoryDialog,
      ),
    );
  }
}