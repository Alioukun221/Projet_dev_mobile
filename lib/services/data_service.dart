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

  Future<void> init() async {
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _categoryBox = await Hive.openBox<models.Category>('categories');
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

  Future<void> addCategory(models.Category category) async {
    await _categoryBox.add(category);
  }

  Future<void> updateCategory(models.Category category) async {
    await category.save();
  }

  Future<void> deleteCategory(models.Category category) async {
    await category.delete();
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