import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/config/supabase_config.dart';
import 'package:spendwise/pages/splash_screen.dart';
import 'package:spendwise/pages/about_page.dart';
import 'package:spendwise/providers/locale_provider.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/services/permission_service.dart';
import 'package:spendwise/services/connectivity_service.dart';
import 'package:spendwise/services/local_cache_service.dart';
import 'package:provider/provider.dart';

import 'pages/categories_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement
  await dotenv.load(fileName: '.env');

  // Initialiser Hive (pour le cache offline)
  await Hive.initFlutter();

  // Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialiser les services offline
  await ConnectivityService.instance.init();
  await LocalCacheService.instance.init();

  // Initialiser les permissions
  final permissionService = PermissionService();
  await permissionService.requestAllPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const FinanceApp(),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      locale: localeProvider.locale,
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
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
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
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
