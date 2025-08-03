import 'package:flutter/material.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/services/data_service.dart';

class AddPlanning extends StatefulWidget {
  final bool isDarkMode;
  const AddPlanning({super.key, required this.isDarkMode});

  @override
  State<AddPlanning> createState() => _AddPlanningState();
}

class _AddPlanningState extends State<AddPlanning> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  String? _selectedCategory;

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? Colors.grey[850] : null,
        title: Text(
          'Nouveau budget',
          style: TextStyle(color: widget.isDarkMode ? Colors.white : null),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<List<String>>(
                  stream: Stream.fromFuture(
                      Future.value(DataService().getAllCategories())),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final categories = snapshot.data!;
                    if (categories.isEmpty) {
                      return Column(
                        children: [
                          Text(
                            'Aucune catégorie disponible',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.red[300]
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/categories');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.isDarkMode ? Colors.grey[800] : null,
                            ),
                            child: const Text('Créer une catégorie'),
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
                              color: widget.isDarkMode ? Colors.white : null,
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
                      dropdownColor:
                          widget.isDarkMode ? Colors.grey[850] : null,
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        labelStyle: TextStyle(
                          color: widget.isDarkMode ? Colors.grey[400] : null,
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: widget.isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: widget.isDarkMode
                                ? Colors.blue[300]!
                                : Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style:
                      TextStyle(color: widget.isDarkMode ? Colors.white : null),
                  decoration: InputDecoration(
                    labelText: 'Montant',
                    labelStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : null),
                    prefixText: 'CFA ',
                    prefixStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : null),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[400]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            widget.isDarkMode ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  style:
                      TextStyle(color: widget.isDarkMode ? Colors.white : null),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : null),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[400]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            widget.isDarkMode ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date de début',
                    style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : null),
                  ),
                  subtitle: Text(
                    '${startDate.day}/${startDate.month}/${startDate.year}',
                    style: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : null),
                  ),
                  trailing: Icon(Icons.calendar_today,
                      color: widget.isDarkMode ? Colors.grey[400] : null),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: widget.isDarkMode
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
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    'Date de fin',
                    style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : null),
                  ),
                  subtitle: Text(
                    '${endDate.day}/${endDate.month}/${endDate.year}',
                    style: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : null),
                  ),
                  trailing: Icon(Icons.calendar_today,
                      color: widget.isDarkMode ? Colors.grey[400] : null),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: widget.isDarkMode
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
                      setState(() => endDate = date);
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
              'Annuler',
              style:
                  TextStyle(color: widget.isDarkMode ? Colors.grey[400] : null),
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
              backgroundColor: widget.isDarkMode ? Colors.grey[800] : null,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showAddBudgetDialog(context),
          child: const Text("Ajouter un budget"),
        ),
      ),
    );
  }
}
