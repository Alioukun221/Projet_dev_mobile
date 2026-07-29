import 'package:flutter/material.dart';
import 'package:spendwise/constants/category_icons.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/utils/app_format.dart';
import 'package:spendwise/utils/user_error.dart';
import 'package:spendwise/widgets/app_empty_state.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  static const Color _primary = Color(0xFF005EFF);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  IconData _iconFor(String category) => CategoryIcons.forName(category);

  // --------------- Input decoration helper ---------------
  InputDecoration _inputDecoration({
    required String label,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
      prefixText: prefix,
      prefixStyle: TextStyle(color: context.appTextSecondary),
      filled: true,
      fillColor: context.isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.appBorderColor),
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
    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: context.appTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.planning,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: StreamBuilder<List<Budget>>(
        stream: SupabaseDataService().budgetsStream,
        builder: (context, snapshot) {
          final budgets = snapshot.data ?? [];
          if (!SupabaseDataService().isFirstLoadComplete) {
            return const Center(child: CircularProgressIndicator());
          }
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
                            color: context.appTextPrimary,
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
      ),
    );
  }

  // =====================================================================
  //  EMPTY STATE
  // =====================================================================
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.account_balance_wallet_rounded,
      title: l10n.noPlanning,
      subtitle: l10n.createFirstPlanning,
      iconColor: _primary,
      iconBgColor: _primary.withOpacity(0.08),
      action: ElevatedButton.icon(
        onPressed: () => _showAddBudgetDialog(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(l10n.createPlanning),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
            color: context.appCardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.15 : 0.04),
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
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(context, budget.amount),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appTextSecondary,
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
                children: [
                  // Spent
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.spent}: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appTextSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            formatMoney(context, budget.spent),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Remaining
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.remaining}: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appTextSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            formatMoney(context, budget.remaining),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isOver ? _red : _green,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  // =====================================================================
  //  ADD BUDGET DIALOG
  // =====================================================================
  void _showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    String? dialogCategory;
    final categoriesFuture = SupabaseDataService().getAllCategoryNames();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: context.appCardColor,
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
                                color: context.appTextPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category dropdown
                        StreamBuilder<List<String>>(
                          stream: Stream.fromFuture(categoriesFuture),
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

                            if (dialogCategory != null &&
                                !categories.contains(dialogCategory)) {
                              dialogCategory = categories.first;
                            } else if (dialogCategory == null &&
                                categories.isNotEmpty) {
                              dialogCategory = categories.first;
                            }

                            return DropdownButtonFormField<String>(
                              value: dialogCategory,
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: context.appTextPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    dialogCategory = value;
                                  });
                                }
                              },
                              dropdownColor: context.appCardColor,
                              decoration: _inputDecoration(
                                label: AppLocalizations.of(context)!.category,
                              ),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: context.appTextSecondary),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Amount field
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.amount,
                            prefix: '${appCurrency(context)} ',
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
                            color: context.appTextPrimary,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.description,
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
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: context.isDark
                                        ? ColorScheme.dark(
                                            primary: _primary,
                                            onPrimary: Colors.white,
                                            surface: AppTheme.darkCardColor,
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
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: context.isDark
                                        ? ColorScheme.dark(
                                            primary: _primary,
                                            onPrimary: Colors.white,
                                            surface: AppTheme.darkCardColor,
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
                                    side: BorderSide(
                                        color: context.appBorderColor),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                  style: TextStyle(
                                    color: context.appTextSecondary,
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
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    if (dialogCategory == null) {
                                      return;
                                    }
                                    try {
                                      final categoryId =
                                          await SupabaseDataService()
                                              .getCategoryIdByName(
                                                  dialogCategory!);
                                      final budget = Budget(
                                        categoryId: categoryId,
                                        amount:
                                            double.parse(amountController.text),
                                        startDate: startDate,
                                        endDate: endDate,
                                        description: descriptionController.text,
                                      );
                                      await SupabaseDataService()
                                          .addBudget(budget);
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(userErrorMessage(e,
                                              AppLocalizations.of(context)!)),
                                          backgroundColor: _red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      );
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
          color: context.isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: context.appTextSecondary),
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
        backgroundColor: context.appCardColor,
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
                  color: context.appTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.deleteConfirmationContent}  "${budget.categoryName ?? ''}" ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appTextSecondary,
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
                          side: BorderSide(color: context.appBorderColor),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(
                          color: context.appTextSecondary,
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
