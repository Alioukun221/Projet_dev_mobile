// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
// Pour formater les dates
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/services/data_service.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: DataService().getTransactionsListenable(),
      builder: (context, Box<Transaction> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Aucune donnée',
                  style: AppTheme.titleMedium.copyWith(
                    color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Ajoutez des transactions pour voir les statistiques',
                  style: AppTheme.bodyMedium.copyWith(
                    color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
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
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildSummaryCard(
                      'Retraits',
                      totalExpenses,
                      AppTheme.errorColor,
                      isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Graphique en barres
              Text(
                'Évolution des transactions',
                style: AppTheme.titleLarge.copyWith(
                  color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Container(
                height: 300,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                  boxShadow: isDarkMode ? null : AppTheme.shadowM,
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                value == 0 ? 'Dépôts' : 'Retraits',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
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
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (totalIncome > totalExpenses ? totalIncome : totalExpenses) / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                          width: 1,
                        ),
                        left: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: totalIncome,
                            color: AppTheme.successColor,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
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
                              top: Radius.circular(6),
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
                style: AppTheme.titleLarge.copyWith(
                  color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Container(
                height: 300,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                  boxShadow: isDarkMode ? null : AppTheme.shadowM,
                ),
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: totalIncome,
                        title: 'Dépôts',
                        color: AppTheme.successColor,
                        radius: 100,
                        titleStyle: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: totalExpenses,
                        title: 'Retraits',
                        color: AppTheme.errorColor,
                        radius: 100,
                        titleStyle: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Dépôts', AppTheme.successColor, isDarkMode),
                  const SizedBox(width: AppTheme.spacingL),
                  _buildLegendItem('Retraits', AppTheme.errorColor, isDarkMode),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        boxShadow: isDarkMode ? null : AppTheme.shadowM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.titleMedium.copyWith(
              color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '${amount.toStringAsFixed(2)} CFA',
            style: AppTheme.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDarkMode) {
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
            color: isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
