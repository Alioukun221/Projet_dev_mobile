import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/l10n/wo_material_localizations.dart';
import 'package:spendwise/pages/splash_screen.dart';
import 'package:spendwise/pages/about_page.dart';
import 'package:spendwise/providers/locale_provider.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/services/permission_service.dart';
import 'models/transaction.dart'; // importe du modèle
import 'models/budget.dart';
import 'models/category.dart';
import 'package:provider/provider.dart';

import 'pages/categories_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les permissions
  final permissionService = PermissionService();
  await permissionService.requestAllPermissions();

  // Initialiser Hive
  await Hive.initFlutter();

  // Enregistrer les adaptateurs
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ColorAdapter());

  // Initialiser le service de données
  await DataService().init();

  // Ouvrir les boîtes
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<String>('deleted_categories');

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const FinanceApp(),
    ),
  );
  // runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      locale: localeProvider.locale,
      title: 'SpendWise',
      localizationsDelegates: [
        AppLocalizations.delegate,
        // WoMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), //  English
        Locale('fr'), // french
        Locale('es'), // Espagnol
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('fr');
      },
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/categories': (context) => const CategoriesPage(
              isDarkMode: true,
            ),
        '/settings': (context) => const AboutPage(
              isDarkMode: false,
            ),
      },
    );
  }
}
