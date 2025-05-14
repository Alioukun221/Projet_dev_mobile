import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/services/data_service.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  final List<String> _defaultCategories = [
    'Alimentation',
    'Transport',
    'Logement',
    'Loisirs',
    'Santé',
    'Éducation',
    'Autres'
  ];

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
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
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Aucun budget',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Créez votre premier budget',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                ElevatedButton.icon(
                  onPressed: () => _showAddBudgetDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Créer un budget'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverviewChart(box),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budgets',
                    style: AppTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
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
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
            boxShadow: AppTheme.shadowS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.category,
                    style: AppTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteBudget(budget),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              LinearProgressIndicator(
                value: budget.progress / 100,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  budget.isOverBudget ? AppTheme.errorColor : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dépensé: ${budget.spent.toStringAsFixed(2)} CFA',
                    style: AppTheme.bodyMedium,
                  ),
                  Text(
                    'Restant: ${budget.remaining.toStringAsFixed(2)} CFA',
                    style: AppTheme.bodyMedium.copyWith(
                      color: budget.isOverBudget ? AppTheme.errorColor : AppTheme.successColor,
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

  Widget _buildOverviewChart(Box<Budget> box) {
    final budgets = DataService().getBudgets();
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: budgets.map((budget) {
            return PieChartSectionData(
              value: budget.amount,
              title: '${budget.category}\n${budget.progress.toStringAsFixed(1)}%',
              color: _getCategoryColor(budget.category),
              radius: 50,
              titleStyle: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Alimentation': Colors.green,
      'Transport': Colors.blue,
      'Logement': Colors.purple,
      'Loisirs': Colors.orange,
      'Santé': Colors.red,
      'Éducation': Colors.teal,
      'Autres': Colors.grey,
    };
    return colors[category] ?? AppTheme.primaryColor;
  }

  void _showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String selectedCategory = _defaultCategories.first;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau budget'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    prefixText: 'CFA ',
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
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                ListTile(
                  title: const Text('Date de début'),
                  subtitle: Text(
                    '${startDate.day}/${startDate.month}/${startDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      startDate = date;
                    }
                  },
                ),
                ListTile(
                  title: const Text('Date de fin'),
                  subtitle: Text(
                    '${endDate.day}/${endDate.month}/${endDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
            child: const Text('Annuler'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer le budget "${budget.category}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              DataService().deleteBudget(budget);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 