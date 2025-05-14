// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EditTransactionPage extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionPage({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late String _selectedType;
  late String _selectedCategory;
  late DateTime _selectedDate;

  final List<String> _categories = [
    'Alimentation',
    'Transport',
    'Logement',
    'Loisirs',
    'Santé',
    'Éducation',
    'Autres'
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(text: widget.transaction.montant.toString());
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateBudget(double oldAmount, double newAmount) {
    final budgetBox = Hive.box<Budget>('budgets');
    
    // Annuler l'ancienne dépense
    if (widget.transaction.type == 'retrait') {
      final oldBudgets = budgetBox.values.where((budget) {
        return budget.category == widget.transaction.category &&
            widget.transaction.date.isAfter(budget.startDate) &&
            widget.transaction.date.isBefore(budget.endDate);
      }).toList();

      if (oldBudgets.isNotEmpty) {
        final oldBudget = oldBudgets.first;
        oldBudget.spent -= oldAmount;
        oldBudget.save();
      }
    }

    // Appliquer la nouvelle dépense
    if (_selectedType == 'retrait') {
      final newBudgets = budgetBox.values.where((budget) {
        return budget.category == _selectedCategory &&
            _selectedDate.isAfter(budget.startDate) &&
            _selectedDate.isBefore(budget.endDate);
      }).toList();

      if (newBudgets.isNotEmpty) {
        final newBudget = newBudgets.first;
        newBudget.spent += newAmount;
        newBudget.save();
      }
    }
  }

  void _updateTransaction() {
    if (_formKey.currentState!.validate()) {
      final oldAmount = widget.transaction.montant;
      final newAmount = double.parse(_amountController.text);

      widget.transaction.type = _selectedType;
      widget.transaction.montant = newAmount;
      widget.transaction.description = _descriptionController.text;
      widget.transaction.date = _selectedDate;
      widget.transaction.category = _selectedCategory;
      widget.transaction.save();

      _updateBudget(oldAmount, newAmount);
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la transaction'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmer la suppression'),
                  content: const Text('Voulez-vous vraiment supprimer cette transaction ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Annuler la dépense dans le budget si nécessaire
                        if (widget.transaction.type == 'retrait') {
                          final budgetBox = Hive.box<Budget>('budgets');
                          final budgets = budgetBox.values.where((budget) {
                            return budget.category == widget.transaction.category &&
                                widget.transaction.date.isAfter(budget.startDate) &&
                                widget.transaction.date.isBefore(budget.endDate);
                          }).toList();

                          if (budgets.isNotEmpty) {
                            final budget = budgets.first;
                            budget.spent -= widget.transaction.montant;
                            budget.save();
                          }
                        }
                        
                        widget.transaction.delete();
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Return to previous screen
                      },
                      child: Text(
                        'Supprimer',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Dépôt   '),
                        Icon(Icons.arrow_downward, color: Colors.green),
                      ],
                    ),
                  ),
                  ButtonSegment<String>(
                    value: 'retrait',
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Retrait    '),
                        Icon(Icons.arrow_upward, color: Colors.red),
                      ],
                    ),
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
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
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
                  style: AppTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  side: BorderSide(color: AppTheme.textSecondaryColor.withOpacity(0.2)),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Bouton de mise à jour
              ElevatedButton(
                onPressed: _updateTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                ),
                child: const Text('Mettre à jour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
