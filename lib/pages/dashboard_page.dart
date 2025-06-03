// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/pages/categories_page.dart';
import 'package:spendwise/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Container(
                          //   padding: const EdgeInsets.all(AppTheme.spacingS),
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withOpacity(0.2),
                          //     borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                          //   ),
                          //   child: const Icon(
                          //     Icons.account_balance_wallet,
                          //     color: Colors.white,
                          //   ),
                          // ),
                          // const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Bonjour 👋',
                                      style: AppTheme.headlineMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                Text(
                                  'Voici le résumé de vos finances',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Résumé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCard('Solde', total, AppTheme.primaryColor),
                    _buildSummaryCard('Dépôts', income, AppTheme.successColor),
                    _buildSummaryCard('Retraits', expenses, AppTheme.errorColor),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),
                // Dernières transactions
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        child: Icon(Icons.history, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Dernières transactions',
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                if (recentTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      boxShadow: AppTheme.shadowM,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: AppTheme.textSecondaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            'Aucune transaction pour le moment.',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: recentTransactions
                        .map((tx) => _buildTransactionTile(tx))
                        .toList(),
                  ),
                const SizedBox(height: AppTheme.spacingL),
                
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        child: Icon(Icons.pie_chart, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        "Vue graphique",
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                _buildPieChart(income, expenses),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChart(double income, double expenses) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        boxShadow: AppTheme.shadowM,
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: income,
                    color: AppTheme.successColor,
                    title: 'Dépôts',
                    radius: 100,
                    titleStyle: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: expenses,
                    color: AppTheme.errorColor,
                    title: 'Retraits',
                    radius: 100,
                    titleStyle: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Dépôts', AppTheme.successColor),
              const SizedBox(width: AppTheme.spacingL),
              _buildLegendItem('Retraits', AppTheme.errorColor),
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXS),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
              ),
              child: Icon(
                label == 'Solde' ? Icons.account_balance_wallet :
                label == 'Dépôts' ? Icons.arrow_downward :
                Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              '${amount.toStringAsFixed(2)} ',
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'CFA ',
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        boxShadow: isDarkMode ? null : AppTheme.shadowM,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isDeposit 
                ? AppTheme.successColor.withOpacity(isDarkMode ? 0.2 : 0.1) 
                : AppTheme.errorColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          ),
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDeposit ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
        title: Text(
          tx.description,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              DateFormat('dd/MM/yyyy').format(tx.date),
              style: AppTheme.bodyMedium.copyWith(
                color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isDeposit 
                ? AppTheme.successColor.withOpacity(isDarkMode ? 0.2 : 0.1) 
                : AppTheme.errorColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          ),
          child: Text(
            '${isDeposit ? '+' : '-'}${tx.montant.toStringAsFixed(2)} CFA',
            style: AppTheme.bodyMedium.copyWith(
              color: isDeposit ? AppTheme.successColor : AppTheme.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
