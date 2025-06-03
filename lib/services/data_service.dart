import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/models/category.dart' as models;

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  late Box<Transaction> _transactionBox;
  late Box<Budget> _budgetBox;
  late Box<models.Category> _categoryBox;
  late Box<String> _deletedCategoriesBox;
  final Set<String> _deletedCategories = {};

  Future<void> init() async {
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _categoryBox = await Hive.openBox<models.Category>('categories');
    _deletedCategoriesBox = await Hive.openBox<String>('deleted_categories');
    
    // Charger les catégories supprimées en mémoire
    _deletedCategories.addAll(_deletedCategoriesBox.values);
  }

  // Transactions
  List<Transaction> getTransactions() {
    return _transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox.add(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await transaction.save();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
  }

  // Budgets
  List<Budget> getBudgets() {
    return _budgetBox.values.toList();
  }

  Future<void> addBudget(Budget budget) async {
    await _budgetBox.add(budget);
  }

  Future<void> updateBudget(Budget budget) async {
    await budget.save();
  }

  Future<void> deleteBudget(Budget budget) async {
    await budget.delete();
  }

  // Categories
  List<models.Category> getCategories() {
    return _categoryBox.values.toList();
  }

  List<String> getAllCategories() {
    final defaultCategories = [
      'Alimentation',
      'Transport',
      'Logement',
      'Loisirs',
      'Santé',
      'Éducation',
      'Autres'
    ];
    
    final customCategories = getCategories().map((c) => c.name).toList();
    
    // Combiner les catégories par défaut et personnalisées, en excluant les supprimées
    final allCategories = {...defaultCategories, ...customCategories}
        .where((category) => !_deletedCategories.contains(category))
        .toList();
    allCategories.sort();
    return allCategories;
  }

  String _normalizeCategoryName(String name) {
    // Enlever les espaces au début et à la fin, et convertir en minuscules
    return name.trim().toLowerCase();
  }

  bool categoryExists(String categoryName) {
    final normalizedName = _normalizeCategoryName(categoryName);
    
    // Vérifier dans les catégories par défaut (qui ne sont pas supprimées)
    final defaultCategories = [
      'Alimentation',
      'Transport',
      'Logement',
      'Loisirs',
      'Santé',
      'Éducation',
      'Autres'
    ];
    
    // Vérifier si le nom normalisé correspond à une catégorie par défaut
    if (defaultCategories.any((cat) => _normalizeCategoryName(cat) == normalizedName) && 
        !_deletedCategories.contains(categoryName)) {
      return true;
    }
    
    // Vérifier dans les catégories personnalisées
    return getCategories().any((category) => 
      _normalizeCategoryName(category.name) == normalizedName
    );
  }

  Future<void> addCategory(models.Category category) async {
    // Normaliser le nom de la catégorie avant de vérifier
    final normalizedName = _normalizeCategoryName(category.name);
    
    // Vérifier si le nom est vide après normalisation
    if (normalizedName.isEmpty) {
      throw Exception('Le nom de la catégorie ne peut pas être vide');
    }

    if (categoryExists(category.name)) {
      throw Exception('Une catégorie avec ce nom existe déjà, veuillez utiliser le nom existant pour eviter toute confusion future avec vos categories');
    }

    // Créer une nouvelle catégorie avec le nom normalisé
    final normalizedCategory = models.Category(
      name: category.name.trim(), // Garder la casse originale mais enlever les espaces
      icon: category.icon,
    );
    
    await _categoryBox.add(normalizedCategory);
  }

  Future<void> updateCategory(models.Category category) async {
    await category.save();
  }

  Future<void> deleteCategory(models.Category category) async {
    // Si c'est une catégorie par défaut, l'ajouter à la liste des catégories supprimées
    final defaultCategories = [
      'Alimentation',
      'Transport',
      'Logement',
      'Loisirs',
      'Santé',
      'Éducation',
      'Autres'
    ];
    
    if (defaultCategories.contains(category.name)) {
      _deletedCategories.add(category.name);
      await _deletedCategoriesBox.add(category.name);
    }
    
    await category.delete();
  }

  Future<void> restoreDefaultCategories() async {
    // Vider la boîte des catégories
    await _categoryBox.clear();
    
    // Vider la liste des catégories supprimées
    _deletedCategories.clear();
    await _deletedCategoriesBox.clear();
  }

  // Ajouter une nouvelle fonction pour initialiser les catégories par défaut
  Future<void> initializeDefaultCategories() async {
    final defaultCategories = [
      'Alimentation',
      'Transport',
      'Logement',
      'Loisirs',
      'Santé',
      'Éducation',
      'Autres'
    ];

    // Vérifier quelles catégories par défaut existent déjà
    final existingCategories = getCategories();
    final existingNames = existingCategories.map((c) => c.name).toSet();

    // Ajouter les catégories par défaut manquantes
    for (final categoryName in defaultCategories) {
      if (!existingNames.contains(categoryName)) {
        final category = models.Category(name: categoryName);
        await _categoryBox.add(category);
      }
    }
  }

  // Listeners
  ValueListenable<Box<Transaction>> getTransactionsListenable() {
    return _transactionBox.listenable();
  }

  ValueListenable<Box<Budget>> getBudgetsListenable() {
    return _budgetBox.listenable();
  }

  ValueListenable<Box<models.Category>> getCategoriesListenable() {
    return _categoryBox.listenable();
  }
} 