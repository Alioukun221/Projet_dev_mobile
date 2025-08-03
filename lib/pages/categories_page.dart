import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/services/data_service.dart';
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

  final List<String> _defaultCategories = [
    'Alimentation',
    'Transport',
    'Logement',
    'Loisirs',
    'Santé',
    'Éducation',
    'Autres'
  ];

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

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategories();
  }

  void _initializeDefaultCategories() {
    final existingCategories = DataService().getCategories();
    final existingNames = existingCategories.map((c) => c.name).toSet();

    for (final categoryName in _defaultCategories) {
      if (!existingNames.contains(categoryName)) {
        final category = Category(name: categoryName);
        DataService().addCategory(category);
      }
    }
  }

  void _restoreDefaultCategories() async {
    try {
      // Restaurer les catégories par défaut via le service
      await DataService().restoreDefaultCategories();

      // Initialiser les catégories par défaut
      await DataService().initializeDefaultCategories();

      if (!mounted) return;

      // Rafraîchir l'interface
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(
              '${AppLocalizations.of(context)!.restoreCategoryError} ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
        await DataService().addCategory(category);
        _nameController.clear();
      } catch (e) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkMode ? Colors.white : Colors.black54,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 2,
        title: Text(
          AppLocalizations.of(context)!.categories,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.restore,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                      AppLocalizations.of(context)!.restoreDefaultCategories),
                  content: Text(
                      AppLocalizations.of(context)!.restoreDefaultCategories),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        _restoreDefaultCategories();
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.restore),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.addCategory,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusM),
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? const Color.fromARGB(255, 63, 60, 60)
                                : (const Color.fromARGB(255, 65, 61,
                                    61)), // ou AppTheme.primaryColor
                            width: 5.0,
                          )),
                      filled: true,
                      fillColor: Colors.white30,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.enterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ElevatedButton(
                    onPressed: _addCategory,
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: DataService().getCategoriesListenable(),
              builder: (context, Box<Category> box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          AppLocalizations.of(context)!.noCategory,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          AppLocalizations.of(context)!.addYourFirstCategory,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final category = box.getAt(index)!;
                    final isDefault =
                        _defaultCategories.contains(category.name);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.grey[500]
                            : AppTheme.surfaceColor,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusL),
                        boxShadow: AppTheme.shadowM,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            _defaultCategoryIcons[category.name] ??
                                Icons.category,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: isDefault
                            ? Text(
                                AppLocalizations.of(context)!.defaultCategory)
                            : Text(
                                AppLocalizations.of(context)!.customCategory),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .deleteConfirmationTitle),
                                content: Text(
                                  '${AppLocalizations.of(context)!.deleteConfirmationContent} ${category.name}" ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      DataService().deleteCategory(category);
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.delete),
                                  ),
                                ],
                              ),
                            );
                          },
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
