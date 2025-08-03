import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  String? _selectedCategory;
  bool _isDarkMode = false; // État pour le mode sombre

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = this.context;
      setState(() {
        _isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mettre à jour le mode sombre en fonction du thème actuel
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: DataService().getBudgetsListenable(),
      builder: (context, Box<Budget> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: _isDarkMode
                      ? Colors.grey[400]
                      : AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  AppLocalizations.of(context)!.noPlanning,
                  style: AppTheme.titleMedium.copyWith(
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  AppLocalizations.of(context)!.createFirstPlanning,
                  style: AppTheme.bodyMedium.copyWith(
                    color: _isDarkMode
                        ? Colors.grey[400]
                        : AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                ElevatedButton.icon(
                    onPressed: () => _showAddBudgetDialog(context),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.createPlanning,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSizeM,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusL),
                      ),
                    )),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.addPlanning,
                    style: AppTheme.titleLarge.copyWith(
                        color: _isDarkMode
                            ? Colors.white
                            : const Color.fromARGB(255, 48, 43, 43),
                        fontWeight: FontWeight.w400),
                  ),
                  IconButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(AppTheme.primaryColor),
                    ),
                    color: AppTheme.primaryColor,
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    onPressed: () => _showAddBudgetDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildBudgetsList(box),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetsList(Box<Budget> box) {
    final budgets = DataService().getBudgets();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[850] : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
            boxShadow: _isDarkMode ? AppTheme.shadowM : AppTheme.shadowS,
            border: _isDarkMode
                ? Border.all(color: const Color.fromARGB(255, 177, 168, 168))
                : Border.all(color: const Color.fromARGB(255, 201, 196, 196)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.category,
                    style: AppTheme.titleMedium.copyWith(
                      color: _isDarkMode
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color:
                          _isDarkMode ? Colors.grey[400] : AppTheme.errorColor,
                    ),
                    onPressed: () => _deleteBudget(budget),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              LinearProgressIndicator(
                value: budget.progress / 100,
                backgroundColor:
                    (_isDarkMode ? Colors.grey[800]! : AppTheme.primaryColor)
                        .withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  budget.isOverBudget
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.spent}: ${budget.spent.toStringAsFixed(2)} CFA',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _isDarkMode
                          ? Colors.grey[400]
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.remaining}: ${budget.remaining.toStringAsFixed(2)} CFA',
                    style: AppTheme.bodyMedium.copyWith(
                      color: budget.isOverBudget
                          ? AppTheme.errorColor
                          : (_isDarkMode
                              ? Colors.grey[400]
                              : AppTheme.successColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[850] : null,
        title: Text(
          AppLocalizations.of(context)!.newPlanning,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : null,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                              backgroundColor:
                                  _isDarkMode ? Colors.grey[800] : null,
                            ),
                            child:
                                Text(AppLocalizations.of(context)!.addCategory),
                          ),
                        ],
                      );
                    }

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
                              color: _isDarkMode ? Colors.white : null,
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
                      dropdownColor: _isDarkMode ? Colors.grey[850] : null,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.category,
                        labelStyle: TextStyle(
                          color: _isDarkMode ? Colors.grey[400] : null,
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                _isDarkMode ? Colors.blue[300]! : Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : null,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.amount,
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : null,
                    ),
                    prefixText: 'CFA ',
                    prefixStyle: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : null,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isDarkMode ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                TextFormField(
                  controller: descriptionController,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : null,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : null,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            _isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isDarkMode ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!
                          .pleaseEnterDescription;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.startDate,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : null,
                    ),
                  ),
                  subtitle: Text(
                    '${startDate.day}/${startDate.month}/${startDate.year}',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : null,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: _isDarkMode ? Colors.grey[400] : null,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: _isDarkMode
                                ? ColorScheme.dark(
                                    primary: Colors.blue[300]!,
                                    onPrimary: Colors.white,
                                    surface: Colors.grey[850]!,
                                    onSurface: Colors.white,
                                  )
                                : null,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      startDate = date;
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.endDate,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : null,
                    ),
                  ),
                  subtitle: Text(
                    '${endDate.day}/${endDate.month}/${endDate.year}',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : null,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: _isDarkMode ? Colors.grey[400] : null,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: _isDarkMode
                                ? ColorScheme.dark(
                                    primary: Colors.blue[300]!,
                                    onPrimary: Colors.white,
                                    surface: Colors.grey[850]!,
                                    onSurface: Colors.white,
                                  )
                                : null,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      endDate = date;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: _isDarkMode ? Colors.grey[400] : null,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final budget = Budget(
                  category: _selectedCategory!,
                  amount: double.parse(amountController.text),
                  startDate: startDate,
                  endDate: endDate,
                  description: descriptionController.text,
                );
                DataService().addBudget(budget);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode ? Colors.grey[800] : null,
            ),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[850] : null,
        title: Text(
          AppLocalizations.of(context)!.deleteConfirmationTitle,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : null,
          ),
        ),
        content: Text(
          '${AppLocalizations.of(context)!.deleteConfirmationContent}  "${budget.category}" ?',
          style: TextStyle(
            color: _isDarkMode ? Colors.grey[400] : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: _isDarkMode ? Colors.grey[400] : null,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              DataService().deleteBudget(budget);
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(
                color: _isDarkMode ? Colors.red[300] : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
