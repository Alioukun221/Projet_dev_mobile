import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import '../models/transaction.dart';

import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedPeriod = 'Mois';
  final List<String> _periods = ['Jour', 'Semaine', 'Mois', 'Année'];
  int _touchedPieIndex = -1;

  // --- Design system helpers ---
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _cardColor => _isDark ? AppTheme.darkCardColor : Colors.white;

  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1A1D29);

  Color get _textSecondary =>
      _isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);

  Color get _border =>
      _isDark ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.04);

  Color get _surfaceColor =>
      _isDark ? AppTheme.darkSurfaceColor : const Color(0xFFF7F8FC);

  static const Color _primaryColor = Color(0xFF005EFF);
  static const Color _greenColor = Color(0xFF22C55E);
  static const Color _redColor = Color(0xFFEF4444);

  String _periodLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Jour':
        return l10n.day;
      case 'Semaine':
        return l10n.week;
      case 'Mois':
        return l10n.month;
      case 'Année':
        return l10n.year;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Transaction>>(
      stream: SupabaseDataService().transactionsStream,
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? [];
        if (allTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 48,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.noData,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.noDataDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final transactions = allTransactions;
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
          if (tx.isDeposit) {
            totalIncome += tx.amount;
          } else {
            totalExpenses += tx.amount;
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // --- Period selector: modern chip pills ---
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // --- Summary cards ---
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.south_west_rounded,
                      label: AppLocalizations.of(context)!.deposit,
                      amount: totalIncome,
                      color: _greenColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.north_east_rounded,
                      label: AppLocalizations.of(context)!.withdrawal,
                      amount: totalExpenses,
                      color: _redColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- Bar chart section ---
              _buildSectionHeader(
                AppLocalizations.of(context)!.transactionEvolution,
              ),
              const SizedBox(height: 12),
              _buildBarChartCard(totalIncome, totalExpenses),
              const SizedBox(height: 28),

              // --- Pie chart section ---
              _buildSectionHeader(
                AppLocalizations.of(context)!.breakdown,
              ),
              const SizedBox(height: 12),
              _buildPieChartCard(totalIncome, totalExpenses),
              const SizedBox(height: 70),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Period selector: pill-shaped chip buttons
  // ------------------------------------------------------------------
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _periodLabel(period),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : _textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Section header (icon + title) -- same pattern as dashboard
  // ------------------------------------------------------------------
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Summary mini-card (icon + label + amount) -- dashboard style
  // ------------------------------------------------------------------
  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormat('#,###', 'fr_FR').format(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Bar chart card
  // ------------------------------------------------------------------
  Widget _buildBarChartCard(double totalIncome, double totalExpenses) {
    final maxY =
        (totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${NumberFormat('#,###', 'fr_FR').format(rod.toY)} CFA',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      value == 0
                          ? AppLocalizations.of(context)!.deposit
                          : AppLocalizations.of(context)!.withdrawal,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == maxY) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      NumberFormat.compact(locale: 'fr_FR').format(value),
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                ((totalIncome > totalExpenses ? totalIncome : totalExpenses) /
                        4)
                    .clamp(1, double.infinity),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: _border,
                strokeWidth: 1,
                dashArray: [6, 4],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: totalIncome,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _greenColor.withOpacity(0.7),
                      _greenColor,
                    ],
                  ),
                  width: 36,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: _greenColor.withOpacity(0.04),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: totalExpenses,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _redColor.withOpacity(0.7),
                      _redColor,
                    ],
                  ),
                  width: 36,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: _redColor.withOpacity(0.04),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Pie chart card with interactive touch + center total + legend
  // ------------------------------------------------------------------
  Widget _buildPieChartCard(double totalIncome, double totalExpenses) {
    final total = totalIncome + totalExpenses;

    if (total == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pie_chart_outline_rounded,
                  size: 32, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noDataDescription,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final incomePercent = (totalIncome / total * 100).toStringAsFixed(0);
    final expensePercent = (totalExpenses / total * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: [
                      PieChartSectionData(
                        value: totalIncome,
                        color: _greenColor,
                        radius: _touchedPieIndex == 0 ? 58 : 48,
                        title: '$incomePercent%',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: _touchedPieIndex == 0 ? 15 : 13,
                        ),
                        titlePositionPercentageOffset: 0.55,
                      ),
                      PieChartSectionData(
                        value: totalExpenses,
                        color: _redColor,
                        radius: _touchedPieIndex == 1 ? 58 : 48,
                        title: '$expensePercent%',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: _touchedPieIndex == 1 ? 15 : 13,
                        ),
                        titlePositionPercentageOffset: 0.55,
                      ),
                    ],
                    centerSpaceRadius: 56,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                  ),
                ),
                // Center text: net total
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat('#,###', 'fr_FR')
                          .format(totalIncome - totalExpenses),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'CFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend row with divider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                AppLocalizations.of(context)!.deposit,
                _greenColor,
                totalIncome,
              ),
              Container(
                width: 1,
                height: 30,
                color: _border,
              ),
              _buildLegendItem(
                AppLocalizations.of(context)!.withdrawal,
                _redColor,
                totalExpenses,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Legend item: rounded square color indicator + label + amount
  // ------------------------------------------------------------------
  Widget _buildLegendItem(String label, Color color, double amount) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat('#,###', 'fr_FR').format(amount)} CFA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}
