// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import '../models/transaction.dart';

class EditTransactionPage extends StatefulWidget {
  final Transaction transaction;

  EditTransactionPage({required this.transaction});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late double _montant;
  late String _description;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction.type;
    _montant = widget.transaction.montant;
    _description = widget.transaction.description;
    _selectedDate = widget.transaction.date;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      widget.transaction.type = _type;
      widget.transaction.montant = _montant;
      widget.transaction.description = _description;
      widget.transaction.date = _selectedDate;

      await widget.transaction.save();

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifier la transaction')),
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
              SizedBox(height: 20),
              TextFormField(
                initialValue: _montant.toString(),
                decoration: InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Montant invalide'
                    : null,
                onSaved: (val) => _montant = double.parse(val!),
              ),
              SizedBox(height: 20),
              TextFormField(
                initialValue: _description,
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
                child: Text('Enregistrer'),
              ),
              SizedBox(height: 20),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Supprimer ?'),
                      content: Text(
                          'Voulez-vous vraiment supprimer cette transaction ?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Annuler')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Supprimer')),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await widget.transaction.delete();
                    Navigator.pop(
                        context); // Revenir à la liste après suppression
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 40, 23, 22),
                ),
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
