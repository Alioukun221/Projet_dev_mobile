// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/pages/edit_transaction_page.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    // Récupérer le thème actuel
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: DataService().getTransactionsListenable(),
      builder: (context, Box<Transaction> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez votre première transaction',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        List<Transaction> transactions = DataService().getTransactions();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isDeposit = transaction.type == 'dépôt';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDeposit
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward_outlined : Icons.arrow_upward_outlined,
                    color: isDeposit ? Colors.green[600] : Colors.red[600],
                    size: 24,
                  ),
                ),
                title: Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(transaction.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDeposit
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDeposit
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDeposit ? '+' : '-'}${transaction.montant.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDeposit ? Colors.green[600] : Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'CFA',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDeposit ? Colors.green[500] : Colors.red[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTransactionPage(
                        transaction: transaction,
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

