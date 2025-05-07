// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/pages/edit_transaction_page.dart';
import '../models/transaction.dart';

class TransactionsPage extends StatelessWidget {
  final Box<Transaction> _transactionBox =
      Hive.box<Transaction>('transactions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _transactionBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          if (box.values.isEmpty) {
            return Center(child: Text('Aucune transaction.'));
          }

          final transactions = box.values.toList().cast<Transaction>();
          transactions.sort(
              (a, b) => b.date.compareTo(a.date)); // plus récentes d'abord

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isDepot = tx.type == 'dépôt';

              return Dismissible(
                key: ValueKey(tx.key),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Confirmer la suppression'),
                      content: Text('Supprimer cette transaction ?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Annuler')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Supprimer')),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => tx.delete(),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(
                      isDepot ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isDepot ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      tx.description,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Date: ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 49, 47, 47),
                      ),
                    ),
                    trailing: Text(
                      '${isDepot ? '+' : '-'}${tx.montant.toStringAsFixed(2)} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDepot ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTransactionPage(transaction: tx),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
