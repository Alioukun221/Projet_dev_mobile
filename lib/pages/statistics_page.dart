// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
// Pour formater les dates
import 'package:spendwise/theme/app_theme.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedPeriod = 'Mois';
  final List<String> _periods = ['Jour', 'Semaine', 'Mois', 'Année'];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Transaction>('transactions').listenable(),
      builder: (context, Box<Transaction> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Aucune donnée',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Ajoutez des transactions pour voir les statistiques',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final transactions = box.values.toList();
        final now = DateTime.now();
        DateTime startDate;

        switch (_selectedPeriod) {
          case 'Jour':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'Semaine':
            startDate = now.subtract(Duration(days: now.weekday - 1));
            break;
          case 'Mois':
            startDate = DateTime(now.year, now.month, 1);
            break;
          case 'Année':
            startDate = DateTime(now.year, 1, 1);
            break;
          default:
            startDate = DateTime(now.year, now.month, 1);
        }

        final filteredTransactions = transactions
            .where((tx) =>
                tx.date.isAfter(startDate) ||
                tx.date.isAtSameMomentAs(startDate))
            .toList();

        double totalIncome = 0;
        double totalExpenses = 0;

        for (var tx in filteredTransactions) {
          if (tx.type == 'dépôt') {
            totalIncome += tx.montant;
          } else {
            totalExpenses += tx.montant;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Période sélection
              SegmentedButton<String>(
                segments: _periods.map((period) {
                  return ButtonSegment<String>(
                    value: period,
                    label: Text(period),
                  );
                }).toList(),
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Résumé
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Dépôts',
                      totalIncome,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildSummaryCard(
                      'Retraits',
                      totalExpenses,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Graphique en barres
              Text(
                'Évolution des transactions',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: [totalIncome, totalExpenses]
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value == 0 ? 'Dépôts' : 'Retraits',
                              style: AppTheme.bodyMedium,
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: AppTheme.bodyMedium,
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: totalIncome,
                            color: AppTheme.successColor,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.borderRadiusS),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: totalExpenses,
                            color: AppTheme.errorColor,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.borderRadiusS),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Graphique circulaire
              Text(
                'Répartition',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: totalIncome,
                        title: 'Dépôts',
                        color: AppTheme.successColor,
                        radius: 50,
                        titleStyle: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: totalExpenses,
                        title: 'Retraits',
                        color: AppTheme.errorColor,
                        radius: 50,
                        titleStyle: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        boxShadow: AppTheme.shadowS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '${amount.toStringAsFixed(2)} CFA',
            style: AppTheme.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
