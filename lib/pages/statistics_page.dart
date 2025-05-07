// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart'; // Pour formater les dates

class StatisticsPage extends StatefulWidget {
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final Box<Transaction> _transactionBox =
      Hive.box<Transaction>('transactions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _transactionBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          // Recalcul des totaux à chaque changement
          double totalDepot = 0;
          double totalRetrait = 0;
          Map<String, double> monthlyTotals = {};

          for (var tx in box.values) {
            String monthKey = DateFormat('yyyy-MM').format(tx.date);
            monthlyTotals[monthKey] =
                (monthlyTotals[monthKey] ?? 0) + tx.montant;

            if (tx.type.toLowerCase() == 'dépôt') {
              totalDepot += tx.montant;
            } else if (tx.type.toLowerCase() == 'retrait') {
              totalRetrait += tx.montant;
            }
          }

          double soldeTotal = totalDepot - totalRetrait;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text("Les totaux",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _buildSummaryCard('Total Dépôts', totalDepot),
                    _buildSummaryCard('Total Retraits', totalRetrait),
                    _buildSummaryCard('Solde Total', soldeTotal),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Graphiques",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                _buildPieChart(totalDepot, totalRetrait),
                const SizedBox(height: 20),
                _buildBarChart(monthlyTotals),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$title :',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(2)} FCFA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: value >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double depot, double retrait) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: depot,
              color: Colors.green,
              title: 'Dépôt',
              radius: 50,
              titleStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: retrait,
              color: Colors.red,
              title: 'Retrait',
              radius: 50,
              titleStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> monthlyTotals) {
    final monthLabels = {
      1: 'Jan',
      2: 'Fév',
      3: 'Mar',
      4: 'Avr',
      5: 'Mai',
      6: 'Juin',
      7: 'Juil',
      8: 'Août',
      9: 'Sep',
      10: 'Oct',
      11: 'Nov',
      12: 'Déc',
    };

    List<BarChartGroupData> barGroups = monthlyTotals.entries.map((entry) {
      final date = DateTime.parse('${entry.key}-01');
      final month = date.month;

      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blueAccent,
            width: 18,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 0,
              color: Colors.grey.shade200,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    double maxY = monthlyTotals.isEmpty
        ? 100
        : (monthlyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2)
            .ceilToDouble();

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 4,
                getTitlesWidget: (value, _) => Text('${value.toInt()}'),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final label = monthLabels[value.toInt()] ?? '';
                  return Text(label, style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (touchedBarGroup) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(0)} F',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
