import 'package:expense_tracker/settings_screen.dart';
import 'package:expense_tracker/stats_screen.dart';
import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'add_expense_screen.dart';
import 'categories_screen.dart';
import 'edit_expense_screen.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF5B9EE1);

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  double _totalPeriod = 0.0;
  bool _isLoading = true;

  // Gestion du filtre Année / Mois
  int? _selectedYear;
  int? _selectedMonth;
  List<int> _availableYears = [];

  final Map<int, String> _monthsMap = {
    1: 'Janvier', 2: 'Février', 3: 'Mars', 4: 'Avril',
    5: 'Mai', 6: 'Juin', 7: 'Juillet', 8: 'Août',
    9: 'Septembre', 10: 'Octobre', 11: 'Novembre', 12: 'Décembre'
  };

  @override
  void initState() {
    super.initState();
    _loadDataOnStart();
  }

  Future<void> _loadDataOnStart() async {
    try {
      await DatabaseHelper.instance.database;
      await _refreshData();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    final rawData = await DatabaseHelper.instance.getExpenses();
    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);

    // Extraire les années disponibles à partir des données (ou année courante par défaut)
    Set<int> years = {};
    for (var item in data) {
      // On essaie d'extraire l'année de la date (si stockée en string ou timestamp)
      // Par défaut, si pas de vraie date parsable, on prend l'année en cours (2026)
      years.add(2026);
    }

    // Ajoute l'année en cours par sécurité
    years.add(DateTime.now().year);

    List<int> sortedYears = years.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _allExpenses = data;
      _availableYears = sortedYears;
      _selectedYear ??= sortedYears.first;
      _selectedMonth ??= DateTime.now().month;

      _filterAndSortData();
      _isLoading = false;
    });
  }

  void _filterAndSortData() {
    List<Map<String, dynamic>> filtered = [];
    double total = 0.0;

    for (var item in _allExpenses) {
      // On extrait l'année et le mois de la date enregistrée (format YYYY-MM-DD ou DateTime)
      // Si ton champ date est stocké sous forme de String (ex: "2026-07-15"), on extrait l'année/mois :
      String dateStr = item['date'] ?? '';
      DateTime? expenseDate = DateTime.tryParse(dateStr);

      int expenseYear = expenseDate?.year ?? DateTime.now().year;
      int expenseMonth = expenseDate?.month ?? DateTime.now().month;

      // On vérifie si ça correspond au filtre sélectionné
      if (expenseYear == _selectedYear && expenseMonth == _selectedMonth) {
        filtered.add(item);
        total += (item['amount'] as num).toDouble();
      }
    }

    // Tri par défaut du plus récent au plus ancien
    filtered.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

    setState(() {
      _filteredExpenses = filtered;
      _totalPeriod = total;
    });
  }

  IconData _getIconForCategory(String? iconName) {
    switch (iconName) {
      case 'home': return Icons.home;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'restaurant': return Icons.restaurant;
      default: return Icons.shopping_cart;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF5B9EE1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mes Dépenses',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, color: Color(0xFF1A1A1A)),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen()));
              _refreshData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: Color(0xFF1A1A1A)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteurs Année > Mois (Le filtre hiérarchique)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(labelText: 'Année', border: InputBorder.none, isDense: true),
                      items: _availableYears.map((year) {
                        return DropdownMenuItem<int>(value: year, child: Text('$year', style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedYear = val;
                          _filterAndSortData();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(labelText: 'Mois', border: InputBorder.none, isDense: true),
                      items: _monthsMap.entries.map((entry) {
                        return DropdownMenuItem<int>(value: entry.key, child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMonth = val;
                          _filterAndSortData();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Carte du total pour la période sélectionnée
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total ${_selectedMonth != null ? _monthsMap[_selectedMonth] : ''} ${_selectedYear ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalPeriod.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Dépenses de la période',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),

            // Liste des dépenses filtrées
            _filteredExpenses.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Aucune dépense pour cette période.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredExpenses.length,
              itemBuilder: (context, index) {
                final item = _filteredExpenses[index];
                final title = item['title'] ?? '';
                final category = item['category_name'] ?? 'Autre';
                final amount = (item['amount'] as num).toDouble();
                final iconName = item['category_icon'];

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditExpenseScreen(expense: item)),
                    );
                    if (result == true) _refreshData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_getIconForCategory(iconName), color: primaryBlue),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '-${amount.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
          if (result == true) _refreshData();
        },
      ),
    );
  }
}