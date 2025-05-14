import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
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
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Budget>('budgets').listenable(),
      builder: (context, Box<Budget> budgetBox, _) {
        if (budgetBox.isEmpty) {
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
                  'Aucun budget défini',
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
                const SizedBox(height: AppTheme.spacingL),
                ElevatedButton.icon(
                  onPressed: () => _showAddBudgetDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un budget'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vos budgets',
                    style: AppTheme.headlineMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBudgetDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              _buildBudgetsList(budgetBox),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Vue d\'ensemble',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildOverviewChart(budgetBox),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetsList(Box<Budget> budgetBox) {
    final budgets = budgetBox.values.toList();
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

  Widget _buildOverviewChart(Box<Budget> budgetBox) {
    final budgets = budgetBox.values.toList();
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
    String selectedCategory = _categories.first;
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
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                  ),
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
                  category: selectedCategory,
                  amount: double.parse(amountController.text),
                  startDate: startDate,
                  endDate: endDate,
                  description: descriptionController.text,
                );
                Hive.box<Budget>('budgets').add(budget);
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
        title: const Text('Supprimer le budget'),
        content: const Text('Voulez-vous vraiment supprimer ce budget ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              budget.delete();
              Navigator.pop(context);
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
} 