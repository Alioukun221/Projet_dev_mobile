// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'dépôt';
  double _montant = 0;
  String _description = '';
  DateTime _selectedDate = DateTime.now();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_description.isEmpty) {
        _description = 'Pas de description';
      }

      final newTransaction = Transaction(
        type: _type,
        montant: _montant,
        description: _description,
        date: _selectedDate,
      );

      final box = Hive.box<Transaction>('transactions');
      await box.add(newTransaction);

      Navigator.pop(context); // Revenir à la page précédente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: ['dépôt', 'retrait'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _type = val!),
                decoration: InputDecoration(labelText: 'Type'),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Montant invalide'
                    : null,
                onSaved: (val) => _montant = double.parse(val!),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (val) => _description = val ?? '',
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          'Date: ${_selectedDate.toLocal()}'.split(' ')[0])),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Text('Choisir'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Ajouter'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
