import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/pages/splash_screen.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'models/transaction.dart'; // importe ton modèle
import 'models/budget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Budget>('budgets');
  
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
    );
  }
}
