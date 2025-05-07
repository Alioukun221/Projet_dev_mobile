// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/models/transaction.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Voici le résumé de vos finances',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Résumé
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard(
                      'Solde', total, const Color.fromARGB(255, 0, 140, 255)),
                  _buildSummaryCard('Dépôts', income, Colors.green),
                  _buildSummaryCard('Retraits', expenses, Colors.red),
                ],
              ),

              const SizedBox(height: 24),
              // Dernières transactions
              Text(
                'Dernières transactions',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),
              if (recentTransactions.isEmpty)
                const Text('Aucune transaction pour le moment.')
              else
                Column(
                  children: recentTransactions
                      .map((tx) => _buildTransactionTile(tx))
                      .toList(),
                ),
              // Juste après les "Dernières transactions"
              SizedBox(height: 24),
              Text("Vue graphique",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
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
              color: Colors.green,
              title: 'Dépôts',
              radius: 50,
              titleStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: expenses,
              color: Colors.red,
              title: 'Retraits',
              radius: 50,
              titleStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: SizedBox(
        height: 110,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${amount.toStringAsFixed(2)} ',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'CFA ',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    final isDeposit = tx.type == 'dépôt';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit ? Colors.green : Colors.red,
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(tx.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        subtitle: Text(
          'Date: ${DateFormat('dd/MM/yyyy').format(tx.date)}',
          style: TextStyle(fontSize: 14),
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}${tx.montant.toStringAsFixed(2)} FCFA',
          style: TextStyle(
            fontSize: 14,
            color: isDeposit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
