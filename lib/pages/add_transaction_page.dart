// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class AddTransactionPage extends StatefulWidget {
  final bool isDarkMode;
  const AddTransactionPage({super.key, required this.isDarkMode});

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

  bool get _isDarkMode => widget.isDarkMode;

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
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.newTransations,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: AppTheme.fontSizeL,
          ),
        ),
        centerTitle: true,
        backgroundColor: _isDarkMode ? Colors.grey[850] : null,
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
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<String>(
                    value: 'dépôt',
                    label: Text(AppLocalizations.of(context)!.deposit),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment<String>(
                    value: 'retrait',
                    label: Text(AppLocalizations.of(context)!.withdrawal),
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
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
                  }),
                  foregroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return _isDarkMode ? Colors.grey[400]! : Colors.grey[800]!;
                  }),
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
                          AppLocalizations.of(context)!.noCategory,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.red[300] : Colors.red,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/categories');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                              AppLocalizations.of(context)!.createCategory),
                        ),
                      ],
                    );
                  }

                  // Réinitialiser la catégorie sélectionnée si elle n'existe plus
                  if (_selectedCategory != null &&
                      !categories.contains(_selectedCategory)) {
                    _selectedCategory = categories.first;
                  } else if (_selectedCategory == null &&
                      categories.isNotEmpty) {
                    _selectedCategory = categories.first;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.grey[300]
                                : AppTheme.textPrimaryColor,
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
                      labelText: AppLocalizations.of(context)!.category,
                      labelStyle: TextStyle(
                        color: _isDarkMode
                            ? Colors.grey[400]
                            : AppTheme.textSecondaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[400]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[400]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: _isDarkMode,
                      fillColor: _isDarkMode ? Colors.grey[850] : null,
                    ),
                    dropdownColor: _isDarkMode ? Colors.grey[850] : null,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: _isDarkMode
                          ? Colors.grey[400]
                          : AppTheme.textSecondaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.grey[300]
                      : AppTheme.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.amount,
                  labelStyle: TextStyle(
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : AppTheme.textSecondaryColor,
                  ),
                  prefixText: 'CFA ',
                  prefixStyle: TextStyle(
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : AppTheme.textSecondaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: _isDarkMode,
                  fillColor: _isDarkMode ? Colors.grey[850] : null,
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.toString() == "0") {
                    return AppLocalizations.of(context)!.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return AppLocalizations.of(context)!
                        .pleaseEnterAmountInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.grey[300]
                      : AppTheme.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.description,
                  labelStyle: TextStyle(
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : AppTheme.textSecondaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: _isDarkMode,
                  fillColor: _isDarkMode ? Colors.grey[850] : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterDescription;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Date
              Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[850] : null,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  border: Border.all(
                    color: _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.date,
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.grey[400]
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  subtitle: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.grey[300]
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : AppTheme.textSecondaryColor,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppTheme.primaryColor,
                              onPrimary: Colors.white,
                              surface: _isDarkMode
                                  ? Colors.grey[850]!
                                  : AppTheme.surfaceColor,
                              onSurface: _isDarkMode
                                  ? Colors.grey[300]!
                                  : AppTheme.textPrimaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Bouton de sauvegarde
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedCategory != null) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
