import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class CategoriesPage extends StatefulWidget {
  final bool isDarkMode;
  const CategoriesPage({super.key, required this.isDarkMode});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final Map<String, IconData> _defaultCategoryIcons = {
    'Alimentation': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Logement': Icons.home,
    'Loisirs': Icons.sports_esports,
    'Santé': Icons.medical_services,
    'Éducation': Icons.school,
    'Autres': Icons.more_horiz,
  };

  bool get _isDarkMode => widget.isDarkMode;

  // Design system colors
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

  static const Color _primaryBlue = Color(0xFF005EFF);
  static const Color _redAccent = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
  }

  void _restoreDefaultCategories() async {
    try {
      await SupabaseDataService().restoreDefaultCategories();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            AppLocalizations.of(context)!.error,
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
          ),
          content: Text(
            '${AppLocalizations.of(context)!.restoreCategoryError} ${e.toString()}',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        final category = Category(
          name: _nameController.text,
        );
        await SupabaseDataService().addCategory(category);
        _nameController.clear();
      } catch (e) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              AppLocalizations.of(context)!.error,
              style:
                  TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
            ),
            content: Text(
              e.toString(),
              style: TextStyle(color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryBlue,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: _textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.categories,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.restore,
                    size: 20,
                    color: _textPrimary,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: _cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(
                          AppLocalizations.of(context)!
                              .restoreDefaultCategories,
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          AppLocalizations.of(context)!
                              .restoreDefaultCategories,
                          style: TextStyle(color: _textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _textSecondary,
                            ),
                            child:
                                Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              _restoreDefaultCategories();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _primaryBlue,
                            ),
                            child:
                                Text(AppLocalizations.of(context)!.restore),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add category form
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addCategory,
                        hintStyle: TextStyle(
                          color: _textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: _textSecondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: _isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF7F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _redAccent,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _redAccent,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.enterName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, Color(0xFF3B82F6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _addCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ajouter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category list
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: SupabaseDataService().categoriesStream,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            size: 40,
                            color: _primaryBlue.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.noCategory,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.addYourFirstCategory,
                          style: TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isDefault = category.isDefault;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Icon container
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _defaultCategoryIcons[category.name] ??
                                    Icons.category,
                                color: _primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isDefault
                                        ? AppLocalizations.of(context)!
                                            .defaultCategory
                                        : AppLocalizations.of(context)!
                                            .customCategory,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete button
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _redAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: _redAccent,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: _cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                      title: Text(
                                        AppLocalizations.of(context)!
                                            .deleteConfirmationTitle,
                                        style: TextStyle(
                                          color: _textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: Text(
                                        '${AppLocalizations.of(context)!.deleteConfirmationContent} ${category.name}" ?',
                                        style: TextStyle(
                                          color: _textSecondary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                _textSecondary,
                                          ),
                                          child: Text(
                                              AppLocalizations.of(
                                                      context)!
                                                  .cancel),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await SupabaseDataService()
                                                .deleteCategory(
                                                    category);
                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: _redAccent,
                                          ),
                                          child: Text(
                                              AppLocalizations.of(
                                                      context)!
                                                  .delete),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
