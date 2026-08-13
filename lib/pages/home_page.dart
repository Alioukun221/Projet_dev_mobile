import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/pages/add_transaction_page.dart';
import 'package:spendwise/pages/ai_finance_page.dart';
import 'package:spendwise/pages/dashboard_page.dart';
import 'package:spendwise/pages/about_page.dart';
import 'package:spendwise/pages/planning_page.dart';
import 'package:spendwise/pages/profile_page.dart';
import 'package:spendwise/pages/statistics_page.dart';
import 'package:spendwise/pages/todo_page.dart';
import 'package:spendwise/pages/transactions_page.dart';
import 'package:spendwise/pages/categories_page.dart';
import 'package:spendwise/pages/notification_settings_page.dart';
import 'package:spendwise/pages/pending_transactions_page.dart';
import 'package:spendwise/pages/auth/welcome_page.dart';
import 'package:spendwise/providers/locale_provider.dart';
import 'package:spendwise/providers/profile_provider.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/services/connectivity_service.dart';
import 'package:spendwise/services/local_cache_service.dart';
import 'package:spendwise/services/notification_transaction_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  StreamSubscription? _syncResultSub;

  @override
  void initState() {
    super.initState();
    _syncResultSub = SupabaseDataService().syncResultStream.listen((result) {
      if (!mounted) return;
      final count = result.contains(':') ? result.split(':')[1] : '?';
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.syncPartialFailure(count)),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  void dispose() {
    _syncResultSub?.cancel();
    super.dispose();
  }

  final List<Widget> _pages = [
    const DashboardPage(),
    TransactionsPage(),
    const StatisticsPage(),
    const TodoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    final bg = _isDarkMode ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);
    final cardColor = _isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1A1D29);
    final subtextColor =
        _isDarkMode ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);

    final themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: bg,
        extendBody: true,
        appBar: _buildAppBar(textColor, subtextColor, cardColor),
        drawer: _buildDrawer(bg, cardColor, textColor, subtextColor),
        body: Column(
          children: [
            _buildSyncBanner(),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
        bottomNavigationBar:
            _buildBottomNav(bg, cardColor, textColor, subtextColor),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildSyncBanner() {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.onlineStream,
      initialData: ConnectivityService.instance.isOnline,
      builder: (context, onlineSnap) {
        final isOnline = onlineSnap.data ?? true;
        return StreamBuilder<int>(
          stream: LocalCacheService.instance.pendingOpsStream,
          initialData: LocalCacheService.instance.pendingOpsCount,
          builder: (context, pendingSnap) {
            final pending = pendingSnap.data ?? 0;
            if (isOnline && pending == 0) return const SizedBox.shrink();
            final bgColor =
                isOnline ? Colors.orange.shade700 : const Color(0xFFEF4444);
            final l10n = AppLocalizations.of(context)!;
            final String label;
            if (!isOnline && pending > 0) {
              label = l10n.syncOfflineWithPending(pending);
            } else if (!isOnline) {
              label = l10n.syncOffline;
            } else {
              label = l10n.syncPendingSync(pending);
            }
            return Container(
              width: double.infinity,
              color: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOnline && pending > 0)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.wifi_off_rounded,
                        color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  PreferredSizeWidget _buildAppBar(
      Color textColor, Color subtextColor, Color cardColor) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      title: Builder(
        builder: (context) => Row(
          children: [
            // Avatar / menu trigger
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Builder(builder: (_) {
                return Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: textColor,
                    size: 24,
                  ),
                );
              }),
            ),
            const SizedBox(width: 14),
            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profileProvider.profile?.displayName ?? 'SpendWise',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Notification bell with pending badge
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PendingTransactionsPage(),
                  ),
                );
              },
              child: StreamBuilder<int>(
                stream: NotificationTransactionService().pendingCountStream,
                initialData: NotificationTransactionService().pendingCount,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: textColor,
                          size: 22,
                        ),
                        if (count > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(
      Color bg, Color cardColor, Color textColor, Color subtextColor) {
    final borderColor =
        _isDarkMode ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.06);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Drawer(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header - Profile section
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Row(
                  children: [
                    Builder(builder: (_) {
                      final avatar = ProfilePage.getAvatarById(
                        profileProvider.profile?.avatar ?? 'avatar_1',
                      );
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              avatar.color,
                              avatar.color.withOpacity(0.7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: avatar.color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          avatar.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      );
                    }),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileProvider.profile?.displayName ?? 'SpendWise',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profileProvider.profile?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: subtextColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: borderColor, indent: 24, endIndent: 24),
            const SizedBox(height: 8),

            // Navigation items
            _buildDrawerItem(
              icon: Icons.calendar_month_rounded,
              label: AppLocalizations.of(context)!.planning,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlanningPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.category_rounded,
              label: AppLocalizations.of(context)!.categories,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoriesPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications_active_rounded,
              label: AppLocalizations.of(context)!.notificationSettings,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Assistant finances',
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiFinancePage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.info_rounded,
              label: AppLocalizations.of(context)!.about,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutPage(),
                  ),
                );
              },
            ),

            const Spacer(),

            // Settings section
            Divider(color: borderColor, indent: 24, endIndent: 24),
            const SizedBox(height: 8),

            // Theme toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.amber.withOpacity(0.12)
                        : Colors.indigo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: _isDarkMode ? Colors.amber : Colors.indigo,
                    size: 20,
                  ),
                ),
                title: Text(
                  _isDarkMode
                      ? AppLocalizations.of(context)!.lightMode
                      : AppLocalizations.of(context)!.darkMode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (_) =>
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme(),
                  activeColor: AppTheme.accentColor,
                  activeTrackColor: AppTheme.accentColor.withOpacity(0.3),
                ),
              ),
            ),

            // Language selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)!.language,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: localeProvider.locale,
                      isDense: true,
                      dropdownColor: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: Locale('fr'),
                          child: Text('FR'),
                        ),
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text('EN'),
                        ),
                        DropdownMenuItem(
                          value: Locale('es'),
                          child: Text('ES'),
                        ),
                      ],
                      onChanged: (locale) {
                        if (locale != null) {
                          localeProvider.setLocale(locale);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: borderColor, indent: 24, endIndent: 24),
            const SizedBox(height: 8),

            // Sign out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)!.logout,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFFE53935),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // close drawer
                  final userId = AuthService().currentUser?.id;
                  SupabaseDataService().reset();
                  Provider.of<ProfileProvider>(context, listen: false).clear();
                  await LocalCacheService.instance.clearUserData(userId);
                  await AuthService().signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomePage()),
                    (route) => false,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                AppLocalizations.of(context)!.splashText,
                style: TextStyle(
                  fontSize: 12,
                  color: subtextColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor,
          ),
        ),
        // trailing: Icon(
        //   Icons.chevron_right_rounded,
        //   color: subtextColor,
        //   size: 20,
        // ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNav(
      Color bg, Color cardColor, Color textColor, Color subtextColor) {
    final labels = [
      AppLocalizations.of(context)!.home,
      AppLocalizations.of(context)!.transactions,
      '', // placeholder for FAB
      AppLocalizations.of(context)!.statistic,
      AppLocalizations.of(context)!.todos,
    ];
    final icons = [
      Icons.dashboard_rounded,
      Icons.receipt_long_rounded,
      Icons.add, // placeholder
      Icons.analytics_rounded,
      Icons.checklist_rounded,
    ];
    final outlinedIcons = [
      Icons.dashboard_outlined,
      Icons.receipt_long_outlined,
      Icons.add, // placeholder
      Icons.analytics_outlined,
      Icons.checklist_rounded,
    ];

    // Map _selectedIndex (0-3) to nav index (0,1,3,4) — index 2 is the FAB gap
    int navIndex;
    if (_selectedIndex <= 1) {
      navIndex = _selectedIndex;
    } else {
      navIndex = _selectedIndex + 1;
    }

    // `extendBody: true` fait passer le corps sous la barre : rien ne reserve
    // donc la hauteur de la barre systeme Android. On l'ajoute a la marge, sinon
    // la navigation de l'app se superpose aux boutons du telephone.
    final systemBottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + systemBottomInset),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (index == 2) {
              return const SizedBox(width: 56); // gap for FAB
            }
            final isSelected = index == navIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (index <= 1) {
                    _selectedIndex = index;
                  } else {
                    _selectedIndex = index - 1;
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? icons[index] : outlinedIcons[index],
                      color: isSelected ? AppTheme.primaryColor : subtextColor,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppTheme.primaryColor : subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF005EFF), Color(0xFF008CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionPage(),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
