// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'dépôt';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeSelectedCategory();
  }

  void _initializeSelectedCategory() {
    final categories = DataService().getCategories();
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first.name;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateBudget(double amount) {
    if (_selectedCategory == null) return;
    
    final budgets = DataService().getBudgets().where((budget) {
      return budget.category == _selectedCategory &&
          _selectedDate.isAfter(budget.startDate) &&
          _selectedDate.isBefore(budget.endDate);
    }).toList();

    if (budgets.isNotEmpty) {
      final budget = budgets.first;
      budget.spent += amount;
      DataService().updateBudget(budget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type de transaction
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'dépôt',
                    label: Text('Dépôt'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment<String>(
                    value: 'retrait',
                    label: Text('Retrait'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Catégorie
              StreamBuilder<List<String>>(
                stream: Stream.fromFuture(Future.value(
                  DataService().getCategories().map((c) => c.name).toList(),
                )),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final categories = snapshot.data!;
                  if (categories.isEmpty) {
                    return Column(
                      children: [
                        const Text(
                          'Aucune catégorie disponible',
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/categories');
                          },
                          child: const Text('Créer une catégorie'),
                        ),
                      ],
                    );
                  }

                  // Réinitialiser la catégorie sélectionnée si elle n'existe plus
                  if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
                    _selectedCategory = categories.first;
                  } else if (_selectedCategory == null && categories.isNotEmpty) {
                    _selectedCategory = categories.first;
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  prefixText: 'CFA ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Date
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Bouton de sauvegarde
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedCategory != null) {
                    final amount = double.parse(_amountController.text);
                    if (_selectedType == 'retrait') {
                      _updateBudget(amount);
                    }

                    final transaction = Transaction(
                      type: _selectedType,
                      category: _selectedCategory!,
                      montant: amount,
                      description: _descriptionController.text,
                      date: _selectedDate,
                    );

                    DataService().addTransaction(transaction);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
