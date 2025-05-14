// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour 👋',
                style: AppTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Voici le résumé de vos finances',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingM),

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
              Text(
                'Dernières transactions',
                style: AppTheme.titleLarge,
              ),

              const SizedBox(height: AppTheme.spacingS),
              if (recentTransactions.isEmpty)
                Text(
                  'Aucune transaction pour le moment.',
                  style: AppTheme.bodyLarge,
                )
              else
                Column(
                  children: recentTransactions
                      .map((tx) => _buildTransactionTile(tx))
                      .toList(),
                ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                "Vue graphique",
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingS),
              _buildPieChart(income, expenses),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(double income, double expenses) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: income,
              color: AppTheme.successColor,
              title: 'Dépôts',
              radius: 50,
              titleStyle: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: expenses,
              color: AppTheme.errorColor,
              title: 'Retraits',
              radius: 50,
              titleStyle: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        height: 110,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXS),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          boxShadow: AppTheme.shadowS,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              style: AppTheme.bodyLarge.copyWith(
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        boxShadow: AppTheme.shadowS,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit ? AppTheme.successColor : AppTheme.errorColor,
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(
          tx.description,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Date: ${DateFormat('dd/MM/yyyy').format(tx.date)}',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}${tx.montant.toStringAsFixed(2)} CFA',
          style: AppTheme.bodyMedium.copyWith(
            color: isDeposit ? AppTheme.successColor : AppTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
