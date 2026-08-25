import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      // onOpen permet d'exécuter du code à chaque lancement de l'app (pratique pour le dev)
      onOpen: (db) async {
        await _seedMockDataOnStart(db);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // Table des catégories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // Table des dépenses
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Insertion des catégories de base pour démarrer
    await db.insert('categories', {'name': 'Nourriture', 'icon': 'shopping_cart'});
    await db.insert('categories', {'name': 'Logement', 'icon': 'home'});
    await db.insert('categories', {'name': 'Transport', 'icon': 'local_gas_station'});
    await db.insert('categories', {'name': 'Loisirs', 'icon': 'restaurant'});
  }

  // --- REQUÊTES UTILES ---

  // Récupérer toutes les catégories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories');
  }

  // Récupérer toutes les dépenses
  // Récupérer toutes les dépenses avec le nom de leur catégorie
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT e.id, e.title, e.amount, e.date, e.note, 
             COALESCE(c.name, 'Autre') as category_name, 
             COALESCE(c.icon, 'shopping_cart') as category_icon
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      ORDER BY e.id DESC
    ''');
    return result;
  }

  // Mettre à jour une dépense existante
  Future<int> updateExpense(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('expenses', row, where: 'id = ?', whereArgs: [id]);
  }

  // Insère des données de test sur les 12 derniers mois
  Future<void> _seedMockDataOnStart(Database db) async {
    // Optionnel : si tu veux vider et recréer à chaque fois pour repartir sur une base propre au hot restart :
    await db.delete('expenses');
    await db.delete('categories');

    // 1. Insérer les catégories de base
    await db.insert('categories', {'name': 'Logement', 'icon': 'home'});
    await db.insert('categories', {'name': 'Alimentation', 'icon': 'shopping_cart'});
    await db.insert('categories', {'name': 'Transport', 'icon': 'directions_car'});
    await db.insert('categories', {'name': 'Loisirs', 'icon': 'sports_esports'});
    await db.insert('categories', {'name': 'Santé', 'icon': 'medical_services'});

    final cats = await db.query('categories');

    // Date de référence : Août 2026
    DateTime now = DateTime(2026, 8, 25);
    final randomAmounts = [15.5, 45.0, 120.0, 8.9, 350.0, 65.0, 22.0, 89.0, 210.0, 14.5];

    // Générer des dépenses sur les 12 derniers mois
    for (int i = 0; i < 12; i++) {
      DateTime targetMonth = DateTime(now.year, now.month - i, 1);

      for (int j = 1; j <= 6; j++) {
        var randomCat = cats[(i + j) % cats.length];
        double amount = randomAmounts[(i + j) % randomAmounts.length] * (1 + (j % 3));

        String dayStr = (j * 4).toString().padLeft(2, '0');
        String monthStr = targetMonth.month.toString().padLeft(2, '0');
        String dateStr = '${targetMonth.year}-$monthStr-$dayStr';

        await db.insert('expenses', {
          'title': 'Dépense ${randomCat['name']} $i-$j',
          'amount': amount,
          'date': dateStr,
          'category_id': randomCat['id'],
        });
      }
    }
  }

  Future<int> updateCategory(int id, String name, String icon) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      {'name': name, 'icon': icon},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer une dépense
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Insérer une nouvelle catégorie
  Future<int> insertCategory(String name, String icon) async {
    final db = await instance.database;
    return await db.insert('categories', {'name': name, 'icon': icon});
  }

  // Supprimer une catégorie
  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Insérer une dépense
  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('expenses', row);
  }

  // Migration en bulk des dépenses d'une catégorie vers une autre (Housekeeping !)
  Future<int> migrateExpensesCategory(int oldCategoryId, int newCategoryId) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      {'category_id': newCategoryId},
      where: 'category_id = ?',
      whereArgs: [oldCategoryId],
    );
  }
}

final Map<String, IconData> availableCategoryIcons = {
  // Logement & Factures
  'home': Icons.home,
  'bolt': Icons.bolt, // Électricité / Énergie
  'water_drop': Icons.water_drop, // Eau
  'wifi': Icons.wifi, // Internet / Box
  'phone_iphone': Icons.phone_iphone, // Téléphone mobile
  'tv': Icons.tv, // Abonnements TV / Streaming

  // Alimentation & Courses
  'shopping_cart': Icons.shopping_cart, // Courses générales
  'restaurant': Icons.restaurant, // Resto / Sortie
  'local_cafe': Icons.local_cafe, // Café / Bar
  'local_bar': Icons.local_bar, // Alcool / Sorties
  'bakery_dining': Icons.bakery_dining, // Boulangerie

  // Transport & Véhicule
  'directions_car': Icons.directions_car, // Voiture / Essence
  'directions_bus': Icons.directions_bus, // Transport en commun
  'train': Icons.train, // Train / Voyage
  'flight': Icons.flight, // Avion / Vacances
  'local_gas_station': Icons.local_gas_station, // Essence spécifique
  'two_wheeler': Icons.two_wheeler, // Moto / Scooter / Vélo

  // Loisirs & Tech
  'sports_esports': Icons.sports_esports, // Jeux vidéo
  'computer': Icons.computer, // Hi-Tech / Matériel
  'headphones': Icons.headphones, // Musique / Podcasts
  'movie': Icons.movie, // Cinéma / Sorties
  'fitness_center': Icons.fitness_center, // Sport / Salle de gym
  'sports_soccer': Icons.sports_soccer, // Football / Sports co
  'book': Icons.book, // Livres / Culture
  'palette': Icons.palette, // Art / Loisirs créatifs

  // Santé & Beauté
  'medical_services': Icons.medical_services, // Santé / Docteur / Pharmacie
  'healing': Icons.healing, // Soins
  'spa': Icons.spa, // Bien-être / Massage
  'content_cut': Icons.content_cut, // Coiffeur / Barbier
  'checkroom': Icons.checkroom, // Vêtements / Shopping fringues

  // Vie quotidienne, Animaux & Famille
  'pets': Icons.pets, // Animaux (chat, chien...)
  'school': Icons.school, // Études / Formation
  'child_care': Icons.child_care, // Enfants / Bébé
  'card_giftcard': Icons.card_giftcard, // Cadeaux
  'celebration': Icons.celebration, // Fêtes / Événements
  'volunteer_activism': Icons.volunteer_activism, // Dons / Charité

  // Finances & Divers
  'account_balance': Icons.account_balance, // Banque / Impôts / Frais bancaires
  'savings': Icons.savings, // Épargne / Investissement
  'security': Icons.security, // Assurances
  'work': Icons.work, // Professionnel / Matériel pro
  'category': Icons.category, // Autre / Divers par défaut
};

IconData getCategoryIcon(String? iconName) {
  return availableCategoryIcons[iconName] ?? Icons.category;
}