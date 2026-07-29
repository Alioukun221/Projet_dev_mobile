// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/constants/app_input_decoration.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/utils/app_format.dart';
import 'package:spendwise/utils/user_error.dart';

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

  bool _isLoading = false;
  late final Future<List<String>> _categoriesFuture;
  static const Color _primaryBlue = Color(0xFF005EFF);
  static const Color _greenColor = Color(0xFF22C55E);
  static const Color _redColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController =
        TextEditingController(text: widget.transaction.amount.toString());
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.categoryName ?? '';
    _selectedDate = widget.transaction.date;
    _categoriesFuture = SupabaseDataService().getAllCategoryNames();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final newAmount = double.parse(_amountController.text);
      final categoryId =
          await SupabaseDataService().getCategoryIdByName(_selectedCategory);

      final updated = Transaction(
        id: widget.transaction.id,
        userId: widget.transaction.userId,
        type: _selectedType,
        categoryId: categoryId,
        amount: newAmount,
        description: _descriptionController.text,
        date: _selectedDate,
      );

      await SupabaseDataService().updateTransaction(updated);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userErrorMessage(e, AppLocalizations.of(context)!)),
          backgroundColor: _redColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
              primary: _primaryBlue,
              onPrimary: Colors.white,
              surface: context.isDark
                  ? AppTheme.darkCardColor
                  : AppTheme.surfaceColor,
              onSurface:
                  context.isDark ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked?.hour ?? _selectedDate.hour,
          timePicked?.minute ?? _selectedDate.minute,
        );
      });
    }
  }

  void _showDeleteDialog() {
    final loc = AppLocalizations.of(context)!;
    final pageContext = context;
    showDialog(
      context: pageContext,
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _redColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _redColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.deleteConfirmationTitle,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.deleteTransactionConfirmation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.appTextPrimary,
                          side: BorderSide(
                              color: context.appBorderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          loc.cancel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final dialogNavigator = Navigator.of(context);
                          final pageNavigator = Navigator.of(pageContext);
                          try {
                            await SupabaseDataService()
                                .deleteTransaction(widget.transaction);
                            if (!mounted) return;
                            dialogNavigator.pop(); // Close dialog
                            if (pageNavigator.canPop()) {
                              pageNavigator.pop(true);
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(userErrorMessage(
                                  e,
                                  AppLocalizations.of(pageContext)!,
                                )),
                                backgroundColor: _redColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _redColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          loc.delete,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
    );
  }

  Widget _buildTypeToggle() {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = 'deposit'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedType == 'deposit'
                    ? _greenColor.withOpacity(0.12)
                    : context.appCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedType == 'deposit'
                      ? _greenColor.withOpacity(0.4)
                      : context.appBorderColor,
                  width: _selectedType == 'deposit' ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedType == 'deposit'
                          ? _greenColor.withOpacity(0.15)
                          : context.appTextSecondary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: _selectedType == 'deposit'
                          ? _greenColor
                          : context.appTextSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.deposit,
                    style: TextStyle(
                      color: _selectedType == 'deposit'
                          ? _greenColor
                          : context.appTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = 'withdrawal'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _selectedType == 'withdrawal'
                    ? _redColor.withOpacity(0.12)
                    : context.appCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedType == 'withdrawal'
                      ? _redColor.withOpacity(0.4)
                      : context.appBorderColor,
                  width: _selectedType == 'withdrawal' ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedType == 'withdrawal'
                          ? _redColor.withOpacity(0.15)
                          : context.appTextSecondary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _selectedType == 'withdrawal'
                          ? _redColor
                          : context.appTextSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.withdrawal,
                    style: TextStyle(
                      color: _selectedType == 'withdrawal'
                          ? _redColor
                          : context.appTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.appCardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appBorderColor),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: context.appTextPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          loc.editTransaction,
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: GestureDetector(
                onTap: _showDeleteDialog,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _redColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _redColor.withOpacity(0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _redColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Transaction type toggle cards --
              _buildTypeToggle(),
              const SizedBox(height: 20),

              // -- Category dropdown --
              StreamBuilder<List<String>>(
                stream: Stream.fromFuture(_categoriesFuture),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: _primaryBlue,
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  final categories = snapshot.data!;
                  if (categories.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.appCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: context.appTextSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.noCategory,
                            style: TextStyle(
                              color: _redColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/categories');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(loc.createCategory),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    menuMaxHeight: 400,
                    value: _selectedCategory.isEmpty ? null : _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 15,
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
                    decoration: AppInputDecoration.of(
                      context,
                      label: loc.category,
                    ),
                    dropdownColor: context.appCardColor,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.appTextSecondary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // -- Amount --
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: AppInputDecoration.of(
                  context,
                  label: loc.amount,
                  prefixText: '${appCurrency(context)} ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return loc.pleaseEnterAmountInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // -- Description --
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: AppInputDecoration.of(
                  context,
                  label: loc.description,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterDescription;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // -- Date picker --
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.appCardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appBorderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: _primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.date,
                              style: TextStyle(
                                color: context.appTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year} ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: context.appTextPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.appTextSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // -- Update button with gradient --
              Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [_primaryBlue, Color(0xFF3381FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              loc.update,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
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
