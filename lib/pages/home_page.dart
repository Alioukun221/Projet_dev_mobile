import 'package:flutter/material.dart';
import 'package:spendwise/pages/add_transaction_page.dart';
import 'package:spendwise/pages/dashboard_page.dart';
import 'package:spendwise/pages/developer_page.dart';
import 'package:spendwise/pages/planning_page.dart';
import 'package:spendwise/pages/statistics_page.dart';
import 'package:spendwise/pages/transactions_page.dart';
import 'package:spendwise/pages/categories_page.dart';
import 'package:spendwise/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false; // État local pour le thème

  final List<Widget> _pages = [
    const DashboardPage(),
    TransactionsPage(),
    PlanningPage(),
    const StatisticsPage(),
  ];

  // Méthode pour changer de thème
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Application du thème
    final themeData = _isDarkMode 
        ? ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              secondary: AppTheme.primaryColor.withOpacity(0.8),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              secondary: AppTheme.primaryColor.withOpacity(0.8),
            ),
          );
    
    // Couleurs adaptatives pour le drawer
    final drawerGradient = _isDarkMode 
      ? [Colors.grey[800]!, Colors.grey[900]!]
      : [AppTheme.primaryColor.withOpacity(0.1), Colors.white];
    
    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                ),
                child: Icon(
                  Icons.menu,
                  color: AppTheme.primaryColor,
                ),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          title: Text(
            'SpendWise',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: drawerGradient,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'SpendWise',
                        style: AppTheme.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Gérez vos finances',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
             
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                    ),
                    child: Icon(
                      Icons.category,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    'Catégories',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoriesPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                    ),
                    child: Icon(
                      Icons.info,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    'À propos',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeveloperPage(),
                      ),
                    );
                  },
                ),
                Divider(color: _isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                
              ],
            ),
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          backgroundColor: _isDarkMode ? Colors.grey[850] : null,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Planning',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Statistiques',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTransactionPage()),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
