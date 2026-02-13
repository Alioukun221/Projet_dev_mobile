import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  String? _selectedCategory;

  // --------------- Design system helpers ---------------
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _cardColor =>
      _isDark ? AppTheme.darkCardColor : Colors.white;

  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF1A1D29);

  Color get _textSecondary =>
      _isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);

  Color get _border => _isDark
      ? AppTheme.darkBorderColor
      : Colors.black.withOpacity(0.04);

  static const Color _primary = Color(0xFF005EFF);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  final NumberFormat _fmt = NumberFormat('#,###', 'fr_FR');

  // --------------- Category icon map ---------------
  final Map<String, IconData> _categoryIcons = {
    'alimentation': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'logement': Icons.home_rounded,
    'loisirs': Icons.sports_esports_rounded,
    'sante': Icons.favorite_rounded,
    'santé': Icons.favorite_rounded,
    'education': Icons.school_rounded,
    'éducation': Icons.school_rounded,
    'autres': Icons.more_horiz_rounded,
  };

  IconData _iconFor(String category) =>
      _categoryIcons[category.toLowerCase()] ?? Icons.account_balance_wallet_rounded;

  // --------------- Input decoration helper ---------------
  InputDecoration _inputDecoration({
    required String label,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textSecondary, fontSize: 14),
      prefixText: prefix,
      prefixStyle: TextStyle(color: _textSecondary),
      filled: true,
      fillColor: _isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Budget>>(
      stream: SupabaseDataService().budgetsStream,
      builder: (context, snapshot) {
        final budgets = snapshot.data ?? [];
        if (budgets.isEmpty) {
          return _buildEmptyState(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_rounded,
                          size: 20, color: _primary),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.addPlanning,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: _primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showAddBudgetDialog(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBudgetsList(budgets),
            ],
          ),
        );
      },
    );
  }

  // =====================================================================
  //  EMPTY STATE
  // =====================================================================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 40,
                color: _primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noPlanning,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.createFirstPlanning,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            // Gradient "create" button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [_primary, Color(0xFF3381FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showAddBudgetDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.createPlanning,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  //  BUDGETS LIST
  // =====================================================================
  Widget _buildBudgetsList(List<Budget> budgets) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final progressValue = (budget.progress / 100).clamp(0.0, 1.0);
        final isOver = budget.isOverBudget;
        final progressColor = isOver ? _red : _primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + name + delete
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconFor(budget.categoryName ?? ''),
                      color: progressColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.categoryName ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_fmt.format(budget.amount)} CFA',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _deleteBudget(budget),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: _red.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar with rounded ends
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 8,
                  backgroundColor: progressColor.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 6),

              // Percentage label
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${budget.progress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Spent / Remaining row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Spent
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.spent}: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        '${_fmt.format(budget.spent)} CFA',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _red,
                        ),
                      ),
                    ],
                  ),
                  // Remaining
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.remaining}: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        '${_fmt.format(budget.remaining)} CFA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOver ? _red : _green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================================
  //  ADD BUDGET DIALOG
  // =====================================================================
  void _showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dialog title
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_chart_rounded,
                                color: _primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.newPlanning,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category dropdown
                        StreamBuilder<List<String>>(
                          stream: Stream.fromFuture(
                            SupabaseDataService().getAllCategoryNames(),
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final categories = snapshot.data!;
                            if (categories.isEmpty) {
                              return Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _red.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: _red.withOpacity(0.15)),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.noCategory,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                            context, '/categories');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .addCategory,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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
                                      color: _textPrimary,
                                      fontSize: 14,
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
                              dropdownColor: _cardColor,
                              decoration: _inputDecoration(
                                label:
                                    AppLocalizations.of(context)!.category,
                              ),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: _textSecondary),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Amount field
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.amount,
                            prefix: 'CFA ',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterAmount;
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterAmountInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description field
                        TextFormField(
                          controller: descriptionController,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            label:
                                AppLocalizations.of(context)!.description,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterDescription;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Start date tile
                        _buildDateTile(
                          label: AppLocalizations.of(context)!.startDate,
                          date: startDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: _isDark
                                        ? ColorScheme.dark(
                                            primary: _primary,
                                            onPrimary: Colors.white,
                                            surface:
                                                AppTheme.darkCardColor,
                                            onSurface: Colors.white,
                                          )
                                        : ColorScheme.light(
                                            primary: _primary,
                                          ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // End date tile
                        _buildDateTile(
                          label: AppLocalizations.of(context)!.endDate,
                          date: endDate,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: _isDark
                                        ? ColorScheme.dark(
                                            primary: _primary,
                                            onPrimary: Colors.white,
                                            surface:
                                                AppTheme.darkCardColor,
                                            onSurface: Colors.white,
                                          )
                                        : ColorScheme.light(
                                            primary: _primary,
                                          ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setDialogState(() {
                                endDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 28),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: _border),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [_primary, Color(0xFF3381FF)],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      final categoryId = await SupabaseDataService()
                                          .getCategoryIdByName(_selectedCategory!);
                                      final budget = Budget(
                                        categoryId: categoryId,
                                        amount: double.parse(
                                            amountController.text),
                                        startDate: startDate,
                                        endDate: endDate,
                                        description:
                                            descriptionController.text,
                                      );
                                      await SupabaseDataService().addBudget(budget);
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.save,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------- Date tile helper ---------------
  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final formatted = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  //  DELETE BUDGET DIALOG
  // =====================================================================
  void _deleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.deleteConfirmationTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.deleteConfirmationContent}  "${budget.categoryName ?? ''}" ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: _border),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await SupabaseDataService().deleteBudget(budget);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.delete,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
