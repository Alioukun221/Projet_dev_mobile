// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/category.dart' as models;
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/constants/app_input_decoration.dart';
import 'package:spendwise/utils/app_format.dart';
import 'package:spendwise/utils/user_error.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'withdrawal';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  static const Color _primaryBlue = Color(0xFF005EFF);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Form card container ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.appCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.appBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(context.isDark ? 0.18 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Description field ---
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: AppInputDecoration.of(
                        context,
                        label: AppLocalizations.of(context)!.title,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    // --- Transaction type toggle ---
                    _buildTypeToggle(context),
                    const SizedBox(height: 22),

                    // --- Category dropdown ---
                    _buildCategoryDropdown(context),
                    const SizedBox(height: 18),

                    // --- Amount field ---
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
                        label: AppLocalizations.of(context)!.amount,
                        prefixText: '${appCurrency(context)} ',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.toString() == "0") {
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
                    const SizedBox(height: 18),

                    // --- Date picker ---
                    _buildDatePicker(context),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- Save button ---
              _buildSaveButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== AppBar =====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: _primaryBlue,
              size: 22,
            ),
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.newTransations,
        style: TextStyle(
          color: context.appTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  // ===================== Type Toggle =====================

  Widget _buildTypeToggle(BuildContext context) {
    final isDeposit = _selectedType == 'deposit';
    return Row(
      children: [
        // Deposit card
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = 'deposit'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDeposit
                    ? _green.withOpacity(0.10)
                    : (context.isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF1F3F8)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDeposit
                      ? _green.withOpacity(0.5)
                      : context.appBorderColor,
                  width: isDeposit ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 18,
                    color: isDeposit ? _green : context.appTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.deposit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isDeposit ? FontWeight.w700 : FontWeight.w500,
                      color: isDeposit ? _green : context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Withdrawal card
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = 'withdrawal'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !isDeposit
                    ? _red.withOpacity(0.10)
                    : (context.isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF1F3F8)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !isDeposit
                      ? _red.withOpacity(0.5)
                      : context.appBorderColor,
                  width: !isDeposit ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: !isDeposit ? _red : context.appTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.withdrawal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          !isDeposit ? FontWeight.w700 : FontWeight.w500,
                      color: !isDeposit ? _red : context.appTextSecondary,
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

  // ===================== Category Dropdown =====================

  Widget _buildCategoryDropdown(BuildContext context) {
    return StreamBuilder<List<models.Category>>(
      stream: SupabaseDataService().categoriesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: context.appInputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorderColor),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final allCats =
            snapshot.data!.where((c) => c.isDeleted != true).toList();
        final categories = allCats.map((c) => c.name).toList();

        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _red.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.noCategory,
                  style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/categories'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(AppLocalizations.of(context)!.createCategory),
                  ),
                ),
              ],
            ),
          );
        }

        if (_selectedCategory == null ||
            !categories.contains(_selectedCategory)) {
          final defaultCat = allCats.firstWhere(
            (c) => c.isDefault,
            orElse: () => allCats.first,
          );
          _selectedCategory = defaultCat.name;
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: categories.map((name) {
            return DropdownMenuItem(
              value: name,
              child: Text(
                name,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedCategory = value);
          },
          decoration: AppInputDecoration.of(
            context,
            label: AppLocalizations.of(context)!.category,
          ),
          dropdownColor: context.appCardColor,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: context.appTextSecondary),
        );
      },
    );
  }

  // ===================== Date Picker =====================

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: context.isDark
                    ? ColorScheme.dark(
                        primary: _primaryBlue,
                        onPrimary: Colors.white,
                        surface: context.appCardColor,
                        onSurface: context.appTextPrimary,
                      )
                    : ColorScheme.light(
                        primary: _primaryBlue,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: context.appTextPrimary,
                      ),
                dialogBackgroundColor: context.appCardColor,
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          setState(() {
            _selectedDate = DateTime(
              date.year,
              date.month,
              date.day,
              time?.hour ?? _selectedDate.hour,
              time?.minute ?? _selectedDate.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.appInputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: _primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.date,
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
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
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appTextSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Save Button =====================

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              if (!_formKey.currentState!.validate() ||
                  _selectedCategory == null) {
                return;
              }
              setState(() => _isLoading = true);
              try {
                final amount = double.parse(_amountController.text);
                final categoryId = await SupabaseDataService()
                    .getCategoryIdByName(_selectedCategory!);
                final transaction = Transaction(
                  type: _selectedType,
                  categoryId: categoryId,
                  amount: amount,
                  description: _descriptionController.text,
                  date: _selectedDate,
                );
                await SupabaseDataService().addTransaction(transaction);
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        userErrorMessage(e, AppLocalizations.of(context)!)),
                    backgroundColor: _red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
      child: AnimatedOpacity(
        opacity: _isLoading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF005EFF), Color(0xFF008CFF)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
