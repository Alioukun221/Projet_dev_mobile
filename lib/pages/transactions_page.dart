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
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: _isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Aucune transaction',
                  style: AppTheme.titleMedium.copyWith(
                    color: _isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Ajoutez votre première transaction',
                  style: AppTheme.bodyMedium.copyWith(
                    color: _isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        List<Transaction> transactions = DataService().getTransactions();

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            top: AppTheme.spacingM,
            bottom: 60,
          ),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isDeposit = transaction.type == 'dépôt';

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                boxShadow: _isDarkMode ? null : AppTheme.shadowS,
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
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                  style: AppTheme.bodyMedium.copyWith(
                    color: _isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDeposit ? '+' : '-'}${transaction.montant.toStringAsFixed(2)} CFA',
                      style: AppTheme.bodyLarge.copyWith(
                        color: isDeposit ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      transaction.category,
                      style: AppTheme.bodyMedium.copyWith(
                        color: _isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                onTap: () {
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
            );
          },
        );
      },
    );
  }
}
