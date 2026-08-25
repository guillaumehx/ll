import 'package:flutter/material.dart';
import 'services/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  bool _isLoading = true;
  double _totalYearlyExpense = 0.0;
  double _monthlyAverage = 0.0;
  Map<String, double> _categoryTotals = {};
  List<double> _monthlyTotals = List.filled(12, 0.0);

  @override
  void initState() {
    super.initState();
    _loadAvailableYearsAndData();
  }

  // Détecte uniquement les années qui contiennent des données (ignore les années vides)
  Future<void> _loadAvailableYearsAndData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    // Requête SQLite pour extraire distinctement les années présentes dans la table expenses
    final result = await db.rawQuery("SELECT DISTINCT strftime('%Y', date) as year FROM expenses WHERE date IS NOT NULL ORDER BY year DESC");

    List<int> years = result.map((row) => int.parse(row['year'].toString())).toList();

    // Sécurité : si la base est complètement vide, on met au moins l'année en cours
    if (years.isEmpty) {
      years = [DateTime.now().year];
    }

    // Si l'année sélectionnée actuelle n'a pas de données, on bascule sur la première année disponible la plus récente
    if (!years.contains(_selectedYear)) {
      _selectedYear = years.first;
    }

    setState(() {
      _availableYears = years;
    });

    await _loadStatsForYear(_selectedYear);
  }

  Future<void> _loadStatsForYear(int year) async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    // 1. Total annuel
    final totalResult = await db.rawQuery(
        "SELECT SUM(amount) as total FROM expenses WHERE strftime('%Y', date) = ?",
        [year.toString()]
    );
    double yearlyTotal = totalResult.first['total'] != null ? double.parse(totalResult.first['total'].toString()) : 0.0;

    // 2. Répartition par catégorie
    final catResult = await db.rawQuery('''
      SELECT c.name as category_name, SUM(e.amount) as total
      FROM expenses e
      JOIN categories c ON e.category_id = c.id
      WHERE strftime('%Y', date) = ?
      GROUP BY c.name
    ''', [year.toString()]);

    Map<String, double> categoriesMap = {};
    for (var row in catResult) {
      categoriesMap[row['category_name'].toString()] = double.parse(row['total'].toString());
    }

    // 3. Totaux mois par mois (12 mois)
    List<double> monthly = List.filled(12, 0.0);
    final monthlyResult = await db.rawQuery('''
      SELECT strftime('%m', date) as month, SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y', date) = ?
      GROUP BY month
    ''', [year.toString()]);

    for (var row in monthlyResult) {
      int monthIndex = int.parse(row['month'].toString()) - 1;
      if (monthIndex >= 0 && monthIndex < 12) {
        monthly[monthIndex] = double.parse(row['total'].toString());
      }
    }

    setState(() {
      _selectedYear = year;
      _totalYearlyExpense = yearlyTotal;
      _monthlyAverage = yearlyTotal / 12;
      _categoryTotals = categoriesMap;
      _monthlyTotals = monthly;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF5B9EE1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Thème clair propre
      appBar: AppBar(
        title: const Text('Tableau de bord Analytique', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
        onRefresh: _loadAvailableYearsAndData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- SÉLECTEUR D'ANNÉE HORIZONTAL (Uniquement les années avec des données) ---
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableYears.length,
                itemBuilder: (context, index) {
                  int year = _availableYears[index];
                  bool isSelected = year == _selectedYear;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ChoiceChip(
                      label: Text('$year', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      backgroundColor: Colors.white,
                      elevation: isSelected ? 2 : 0,
                      side: BorderSide(color: isSelected ? primaryBlue : const Color(0xFFE2E8F0)),
                      onSelected: (selected) {
                        if (selected) _loadStatsForYear(year);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // --- CARTES DE SYNTHÈSE ANNUELLE ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Annuel', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('${_totalYearlyExpense.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Moyenne / mois', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('${_monthlyAverage.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- GRAPHIQUE ANNUEL (12 MOIS) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Évolution en $_selectedYear (12 mois)', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(12, (index) {
                        double val = _monthlyTotals[index];
                        double maxVal = _monthlyTotals.isEmpty ? 1.0 : _monthlyTotals.reduce((a, b) => a > b ? a : b);
                        if (maxVal == 0) maxVal = 1.0;
                        double heightFactor = (val / maxVal).clamp(0.05, 1.0);

                        List<String> monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 14,
                              height: 110 * heightFactor,
                              decoration: BoxDecoration(
                                color: val > 0 ? primaryBlue : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(monthNames[index], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- RÉPARTITION PAR CATÉGORIE SUR L'ANNÉE + MOYENNE MENSUELLE ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Répartition Annuelle par Catégorie', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _categoryTotals.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Aucune donnée pour cette année.', style: TextStyle(color: Color(0xFF64748B))),
                  )
                      : Column(
                    children: _categoryTotals.entries.map((entry) {
                      double categoryTotal = entry.value;
                      double percentage = _totalYearlyExpense > 0 ? (categoryTotal / _totalYearlyExpense) * 100 : 0;
                      double categoryMonthlyAverage = categoryTotal / 12; // Moyenne mensuelle pour cette catégorie

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  '${categoryTotal.toStringAsFixed(2)} € (${percentage.toStringAsFixed(1)}%)',
                                  style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Ajout de la moyenne par mois pour la catégorie
                            Text(
                              'Moyenne : ${categoryMonthlyAverage.toStringAsFixed(2)} € / mois',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: primaryBlue,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}