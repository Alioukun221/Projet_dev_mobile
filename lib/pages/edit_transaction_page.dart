// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class EditTransactionPage extends StatefulWidget {
  final Transaction transaction;
  final bool isDarkMode;

  const EditTransactionPage({
    super.key,
    required this.transaction,
    required this.isDarkMode,
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

  bool get _isDarkMode => widget.isDarkMode;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController =
        TextEditingController(text: widget.transaction.montant.toString());
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
    // Annuler l'ancienne dépense
    if (widget.transaction.type == 'retrait') {
      final budgets = DataService().getBudgets().where((budget) {
        return budget.category == widget.transaction.category &&
            widget.transaction.date.isAfter(budget.startDate) &&
            widget.transaction.date.isBefore(budget.endDate);
      }).toList();

      if (budgets.isNotEmpty) {
        final budget = budgets.first;
        budget.spent -= oldAmount;
        DataService().updateBudget(budget);
      }
    }

    // Appliquer la nouvelle dépense
    if (_selectedType == 'retrait') {
      final budgets = DataService().getBudgets().where((budget) {
        return budget.category == _selectedCategory &&
            _selectedDate.isAfter(budget.startDate) &&
            _selectedDate.isBefore(budget.endDate);
      }).toList();

      if (budgets.isNotEmpty) {
        final budget = budgets.first;
        budget.spent += newAmount;
        DataService().updateBudget(budget);
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
      DataService().updateTransaction(widget.transaction);

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
      backgroundColor:
          _isDarkMode ? Colors.grey[800] : AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
        foregroundColor: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
        elevation: 2,
        title: Text('Modifier la transaction',
            style: TextStyle(
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w400)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirmer la suppression',
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                      )),
                  content:
                      Text('Voulez-vous vraiment supprimer cette transaction ?',
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                          )),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler',
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                          )),
                    ),
                    TextButton(
                      onPressed: () {
                        // Annuler la dépense dans le budget si nécessaire
                        if (widget.transaction.type == 'retrait') {
                          final budgets =
                              DataService().getBudgets().where((budget) {
                            return budget.category ==
                                    widget.transaction.category &&
                                widget.transaction.date
                                    .isAfter(budget.startDate) &&
                                widget.transaction.date
                                    .isBefore(budget.endDate);
                          }).toList();

                          if (budgets.isNotEmpty) {
                            final budget = budgets.first;
                            budget.spent -= widget.transaction.montant;
                            DataService().updateBudget(budget);
                          }
                        }

                        DataService().deleteTransaction(widget.transaction);
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Return to previous screen
                      },
                      child: const Text('Supprimer'),
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
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.selected)) {
                        return _isDarkMode
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withOpacity(0.15);
                      }
                      return _isDarkMode ? Colors.grey[700]! : Colors.white;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return _isDarkMode
                          ? Colors.white
                          : const Color.fromARGB(255, 64, 57, 57);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Catégorie
              StreamBuilder<List<String>>(
                stream: Stream.fromFuture(Future.value(
                  DataService().getAllCategories(),
                )),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final categories = snapshot.data!;
                  if (categories.isEmpty) {
                    return Column(
                      children: [
                        Text(
                          'Aucune catégorie disponible',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.red[200] : Colors.red,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/categories');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDarkMode
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Créer une catégorie'),
                        ),
                      ],
                    );
                  }

                  return DropdownButtonFormField<String>(
                    menuMaxHeight: 400,
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white
                                : const Color.fromARGB(255, 109, 98, 98),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      labelStyle: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : AppTheme.textSecondaryColor,
                      ),
                      filled: true,
                      fillColor: _isDarkMode ? Colors.grey[700] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusM),
                        borderSide: BorderSide(
                          color: _isDarkMode
                              ? Colors.white24
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    dropdownColor:
                        _isDarkMode ? Colors.grey[900] : Colors.white,
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant',
                  prefixStyle: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                  ),
                  labelStyle: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                  ),
                  prefixText: 'CFA ',
                  filled: true,
                  fillColor: _isDarkMode ? Colors.grey[700] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                    borderSide: BorderSide(
                      color:
                          _isDarkMode ? Colors.white24 : AppTheme.primaryColor,
                    ),
                  ),
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
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                  ),
                  filled: true,
                  fillColor: _isDarkMode ? Colors.grey[700] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                    borderSide: BorderSide(
                      color:
                          _isDarkMode ? Colors.white24 : AppTheme.primaryColor,
                    ),
                  ),
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
                tileColor: _isDarkMode ? Colors.grey[700] : Colors.white,
                title: Text(
                  'Date',
                  style: TextStyle(
                    color:
                        _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                  ),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: _isDarkMode ? Colors.white : AppTheme.primaryColor,
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Bouton de mise à jour
              ElevatedButton(
                onPressed: _updateTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
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
