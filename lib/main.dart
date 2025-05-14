import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/pages/splash_screen.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/services/data_service.dart';
import 'models/transaction.dart'; // importe ton modèle
import 'models/budget.dart';
import 'models/category.dart';
import 'pages/categories_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Hive
  await Hive.initFlutter();
  
  // Enregistrer les adaptateurs
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ColorAdapter());
  
  // Supprimer les boîtes existantes pour éviter les problèmes de compatibilité
  await Hive.deleteBoxFromDisk('transactions');
  await Hive.deleteBoxFromDisk('budgets');
  await Hive.deleteBoxFromDisk('categories');
  
  // Initialiser le service de données
  await DataService().init();
  
  // Ouvrir les boîtes
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<Category>('categories');
  
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/categories': (context) => const CategoriesPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
