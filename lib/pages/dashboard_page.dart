import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      setState(() {
        _isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: Hive.box<Transaction>('transactions').listenable(),
      builder: (context, Box<Transaction> transactionBox, _) {
        double total = 0;
        double income = 0;
        double expenses = 0;

        List<Transaction> recentTransactions = transactionBox.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        recentTransactions = recentTransactions.take(3).toList();

        for (var tx in transactionBox.values) {
          if (tx.type.toLowerCase() == 'dépôt') {
            income += tx.montant;
            total += tx.montant;
          } else {
            expenses += tx.montant;
            total -= tx.montant;
          }
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                // Header simple
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.dashboard_outlined,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${AppLocalizations.of(context)!.hello} 👋",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.summaryFinance,
                              style: TextStyle(
                                fontSize: 14,
                                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cartes de résumé simplifiées
                Row(
                  children: [
                    _buildSummaryCard(
                      AppLocalizations.of(context)!.balance,
                      total,
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      AppLocalizations.of(context)!.deposit,
                      income,
                      Colors.green[600]!,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      AppLocalizations.of(context)!.withdrawal,
                      expenses,
                      Colors.red[600]!,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Section transactions
                _buildSectionTitle(AppLocalizations.of(context)!.lastTransactions),

                if (recentTransactions.isEmpty)
                  _buildEmptyState(
                    Icons.receipt_outlined,
                    AppLocalizations.of(context)!.emptyTransaction,
                  )
                else
                  Column(
                    children: recentTransactions
                        .map((tx) => _buildTransactionTile(tx))
                        .toList(),
                  ),
                
                const SizedBox(height: 24),

                // Section graphique
                _buildSectionTitle(AppLocalizations.of(context)!.graphicView),
                
                if (income == 0 && expenses == 0)
                  _buildEmptyState(
                    Icons.bar_chart_outlined,
                    AppLocalizations.of(context)!.noDataDescription,
                  )
                else
                  _buildPieChart(income, expenses),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double income, double expenses) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: income,
                    color: Colors.green[600],
                    title: AppLocalizations.of(context)!.deposit,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  PieChartSectionData(
                    value: expenses,
                    color: Colors.red[600],
                    title: AppLocalizations.of(context)!.withdrawal,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
                centerSpaceRadius: 50,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                AppLocalizations.of(context)!.deposit,
                Colors.green[600]!,
              ),
              const SizedBox(width: 30),
              _buildLegendItem(
                AppLocalizations.of(context)!.withdrawal,
                Colors.red[600]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: _isDarkMode ? Colors.grey[300] : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDarkMode ? Colors.grey[900]! : Colors.grey[500]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == AppLocalizations.of(context)!.balance
                  ? Icons.account_balance_wallet_outlined
                  : label == AppLocalizations.of(context)!.deposit
                      ? Icons.arrow_downward_outlined
                      : Icons.arrow_upward_outlined,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'CFA',
              style: TextStyle(
                fontSize: 10,
                color: _isDarkMode ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    final isDeposit = tx.type == 'dépôt';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDeposit
                ? Colors.green[50]
                : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDeposit ? Icons.arrow_downward_outlined : Icons.arrow_upward_outlined,
            color: isDeposit ? Colors.green[600] : Colors.red[600],
            size: 20,
          ),
        ),
        title: Text(
          tx.description,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(tx.date),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isDeposit
                ? Colors.green[50]
                : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${isDeposit ? '+' : '-'}${tx.montant.toStringAsFixed(2)} CFA',
            style: TextStyle(
              fontSize: 14,
              color: isDeposit ? Colors.green[600] : Colors.red[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
