// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/pages/edit_transaction_page.dart';
import 'package:spendwise/theme/app_theme.dart';

class TransactionsPage extends StatelessWidget {
  TransactionsPage({super.key});

  final Box<Transaction> _transactionBox = Hive.box<Transaction>('transactions');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _transactionBox.listenable(),
      builder: (context, Box<Transaction> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Aucune transaction',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Ajoutez votre première transaction',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        List<Transaction> transactions = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isDeposit = transaction.type == 'dépôt';

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
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
                  transaction.description,
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isDeposit ? '+' : '-'}${transaction.montant.toStringAsFixed(2)} CFA',
                      style: AppTheme.bodyMedium.copyWith(
                        color: isDeposit ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTransactionPage(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
