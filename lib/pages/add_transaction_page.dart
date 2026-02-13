// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/supabase_data_service.dart';
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
  String _selectedType = 'deposit';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool get _isDarkMode => widget.isDarkMode;

  // --- Design system colors ---
  Color get _bgColor =>
      _isDarkMode ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);
  Color get _cardColor =>
      _isDarkMode ? AppTheme.darkCardColor : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? Colors.white : const Color(0xFF1A1D29);
  Color get _textSecondary =>
      _isDarkMode ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode
      ? AppTheme.darkBorderColor
      : Colors.black.withOpacity(0.04);
  Color get _inputFill =>
      _isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F3F8);

  static const Color _primaryBlue = Color(0xFF005EFF);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeSelectedCategory();
  }

  void _initializeSelectedCategory() async {
    final categories = await SupabaseDataService().getAllCategoryNames();
    if (categories.isNotEmpty && mounted) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // --- Shared input decoration builder ---
  InputDecoration _buildInputDecoration({
    required String label,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: _textSecondary,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Form card container ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDarkMode ? 0.18 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _buildInputDecoration(
                        label: AppLocalizations.of(context)!.amount,
                        prefixText: 'CFA ',
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
                    const SizedBox(height: 18),

                    // --- Description field ---
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _buildInputDecoration(
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
              Icons.arrow_back_rounded,
              color: _primaryBlue,
              size: 22,
            ),
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.newTransations,
        style: TextStyle(
          color: _textPrimary,
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
                    : (_isDarkMode
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF1F3F8)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDeposit ? _green.withOpacity(0.5) : _borderColor,
                  width: isDeposit ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 18,
                    color: isDeposit ? _green : _textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.deposit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isDeposit ? FontWeight.w700 : FontWeight.w500,
                      color: isDeposit ? _green : _textSecondary,
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
                    : (_isDarkMode
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF1F3F8)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !isDeposit ? _red.withOpacity(0.5) : _borderColor,
                  width: !isDeposit ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: !isDeposit ? _red : _textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.withdrawal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          !isDeposit ? FontWeight.w700 : FontWeight.w500,
                      color: !isDeposit ? _red : _textSecondary,
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
    return StreamBuilder<List<String>>(
      stream: Stream.fromFuture(
        SupabaseDataService().getAllCategoryNames(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!;
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/categories');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        Text(AppLocalizations.of(context)!.createCategory),
                  ),
                ),
              ],
            ),
          );
        }

        // Reset selected category if it no longer exists
        if (_selectedCategory != null &&
            !categories.contains(_selectedCategory)) {
          _selectedCategory = categories.first;
        } else if (_selectedCategory == null && categories.isNotEmpty) {
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
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
          decoration: _buildInputDecoration(
            label: AppLocalizations.of(context)!.category,
          ),
          dropdownColor: _cardColor,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textSecondary,
          ),
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
                colorScheme: _isDarkMode
                    ? ColorScheme.dark(
                        primary: _primaryBlue,
                        onPrimary: Colors.white,
                        surface: _cardColor,
                        onSurface: _textPrimary,
                      )
                    : ColorScheme.light(
                        primary: _primaryBlue,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: _textPrimary,
                      ),
                dialogBackgroundColor: _cardColor,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
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
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: _textSecondary,
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
      onTap: () async {
        if (_formKey.currentState!.validate() && _selectedCategory != null) {
          final amount = double.parse(_amountController.text);
          final categoryId =
              await SupabaseDataService().getCategoryIdByName(_selectedCategory!);

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
        }
      },
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
          child: Text(
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
    );
  }
}
