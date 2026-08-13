// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/category.dart' as models;
import 'package:spendwise/models/todo_task.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/services/todo_notification_service.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/utils/app_format.dart' as app_fmt;
import 'package:spendwise/widgets/app_empty_state.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF97316);
  static const _primaryBlue = Color(0xFF005EFF);

  String _formatAmount(BuildContext context, double amount) =>
      app_fmt.formatMoney(context, amount, withCurrency: false);

  String _formatDate(BuildContext context, DateTime date) =>
      app_fmt.formatDate(context, 'dd/MM/yyyy HH:mm', date);

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        StreamBuilder<List<TodoTask>>(
          stream: SupabaseDataService().todosStream,
          builder: (context, snapshot) {
            if (!SupabaseDataService().isFirstLoadComplete) {
              return const Center(child: CircularProgressIndicator());
            }
            final todos = snapshot.data ?? [];
            if (todos.isEmpty) {
              return _buildEmptyState(l10n);
            }
            return _buildGroupedList(todos, l10n);
          },
        ),
        // Floating add button
        StreamBuilder<List<TodoTask>>(
          stream: SupabaseDataService().todosStream,
          builder: (context, snapshot) {
            final todos = snapshot.data ?? [];
            if (todos.isEmpty) return const SizedBox.shrink();
            return Positioned(
              right: 20,
              bottom: 100,
              child: GestureDetector(
                onTap: () => _showAddEditSheet(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF005EFF), Color(0xFF008CFF)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupedList(List<TodoTask> todos, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    final overdue = todos.where((t) => t.isOverdue).toList();
    final dueToday = todos.where((t) {
      if (t.isOverdue) return false;
      final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return d == today;
    }).toList();
    final thisWeek = todos.where((t) {
      if (t.isOverdue) return false;
      final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return d != today && t.dueDate.isBefore(endOfWeek);
    }).toList();
    final later = todos
        .where((t) => !t.isOverdue && !t.dueDate.isBefore(endOfWeek))
        .toList();

    return ListView(
      // 120 px degagent la barre de navigation flottante ; celle-ci est
      // maintenant remontee de la hauteur de la barre systeme, qu'on ajoute.
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 120 + MediaQuery.of(context).padding.bottom),
      children: [
        if (overdue.isNotEmpty) ...[
          _buildSectionHeader(l10n.overdueTasks, _red),
          ...overdue.map((t) => _buildTodoItem(t, l10n)),
        ],
        if (dueToday.isNotEmpty) ...[
          _buildSectionHeader(l10n.todayTasks, _orange),
          ...dueToday.map((t) => _buildTodoItem(t, l10n)),
        ],
        if (thisWeek.isNotEmpty) ...[
          _buildSectionHeader(l10n.thisWeekTasks, _primaryBlue),
          ...thisWeek.map((t) => _buildTodoItem(t, l10n)),
        ],
        if (later.isNotEmpty) ...[
          _buildSectionHeader(l10n.laterTasks, context.appTextSecondary),
          ...later.map((t) => _buildTodoItem(t, l10n)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(TodoTask todo, AppLocalizations l10n) {
    final typeColor = todo.isDeposit ? _green : _red;
    final typeIcon = todo.isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Dismissible(
      key: Key(todo.id ?? todo.title),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: _red, size: 24),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: context.appCardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.deleteConfirmationTitle,
            style: TextStyle(
                color: context.appTextPrimary, fontWeight: FontWeight.w700),
          ),
          content: Text(
            l10n.deleteTodoContent(todo.title),
            style: TextStyle(color: context.appTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel,
                  style: TextStyle(color: context.appTextSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete, style: const TextStyle(color: _red)),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        if (todo.id != null) {
          await TodoNotificationService().cancelReminder(todo.id!);
        }
        await SupabaseDataService().deleteTodo(todo);
      },
      child: GestureDetector(
        onTap: () => _showAddEditSheet(context, existing: todo),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.appCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _showCompleteDialog(context, todo, l10n),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: typeColor, width: 2),
                    color: Colors.transparent,
                  ),
                  child: todo.isOverdue
                      ? Icon(Icons.warning_amber_rounded, size: 16, color: _red)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Type icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 12),
              // Title + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: context.appTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(context, todo.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: todo.isOverdue
                                ? _red
                                : context.appTextSecondary,
                          ),
                        ),
                        if (todo.categoryName != null) ...[
                          const SizedBox(width: 6),
                          Text('• ${todo.categoryName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.appTextSecondary,
                              )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount + recurrence
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${todo.isDeposit ? "+" : "-"} ${_formatAmount(context, todo.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                  if (todo.recurrence != 'none') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        todo.recurrence == 'weekly'
                            ? l10n.recurrenceWeekly
                            : l10n.recurrenceMonthly,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return AppEmptyState(
      icon: Icons.checklist_rounded,
      title: l10n.noTodos,
      subtitle: l10n.createFirstTodo,
      iconColor: AppTheme.primaryColor,
      iconBgColor: AppTheme.primaryColor.withOpacity(0.08),
      action: ElevatedButton.icon(
        onPressed: () => _showAddEditSheet(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(l10n.addTodo),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
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

  // ============ DIALOGS ============

  Future<void> _showCompleteDialog(
    BuildContext context,
    TodoTask todo,
    AppLocalizations l10n,
  ) async {
    // Capture theme values synchronously — never call Theme.of(context) inside builders
    final card = context.appCardColor;
    final textPrimary = context.appTextPrimary;
    final textSecondary = context.appTextSecondary;
    final inputFill = context.appInputFill;
    final border = context.appBorderColor;

    final amountController =
        TextEditingController(text: todo.amount.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.confirmComplete,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(todo.title,
                style: TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: l10n.amount,
                labelStyle: TextStyle(color: textSecondary, fontSize: 14),
                filled: true,
                fillColor: inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: _primaryBlue, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final adjustedAmount =
                  double.tryParse(amountController.text.replaceAll(',', '.'));
              final nextTodo = await SupabaseDataService()
                  .completeTodo(todo, adjustedAmount: adjustedAmount);
              if (todo.id != null) {
                await TodoNotificationService().cancelReminder(todo.id!);
              }
              if (nextTodo != null) {
                await TodoNotificationService().scheduleReminder(nextTodo);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.markAsDone),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), amountController.dispose);
  }

  // ============ BOTTOM SHEET (ADD / EDIT) ============

  Future<void> _showAddEditSheet(
    BuildContext context, {
    TodoTask? existing,
  }) async {
    // Capture ALL theme values synchronously before any async gap
    // — never call Theme.of(this.context) from inside a modal builder
    final card = context.appCardColor;
    final textPrimary = context.appTextPrimary;
    final textSecondary = context.appTextSecondary;
    final border = context.appBorderColor;
    final inputFill = context.appInputFill;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = existing != null;

    // Local helpers using captured colors (no context needed)
    InputDecoration buildDecoration(String label) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border)),
          focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: _primaryBlue, width: 1.8)),
          errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: _red)),
        );

    Widget typeBtn(StateSetter set,
        {required String value,
        required IconData icon,
        required Color color,
        required bool selected,
        required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: selected ? color : textSecondary, size: 20),
        ),
      );
    }

    Widget recurrenceChip(StateSetter set,
        {required String label,
        required String value,
        required String selected,
        required VoidCallback onTap}) {
      final isSel = value == selected;
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppTheme.primaryColor.withOpacity(0.12) : inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSel ? AppTheme.primaryColor : border,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSel ? AppTheme.primaryColor : textSecondary,
              )),
        ),
      );
    }

    // Pre-fetch categories so the picker has data immediately
    List<models.Category> categories = [];
    try {
      categories = await SupabaseDataService().getCategories();
    } catch (e) {
      debugPrint('TodoPage.getCategories: $e');
    }

    if (!mounted) return;

    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController =
        TextEditingController(text: existing?.amount.toStringAsFixed(0) ?? '');
    String selectedType = existing?.type ?? 'withdrawal';
    String? selectedCategoryId = existing?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    DateTime selectedDate = existing?.dueDate ?? DateTime.now();
    String selectedRecurrence = existing?.recurrence ?? 'none';
    // Pas de GlobalKey<FormState> — Form+GlobalKey dans un showModalBottomSheet
    // enregistre des dépendances WillPopScope/PopScope sur la route qui
    // causent "_dependents.isEmpty" lors de la fermeture du sheet.
    // On valide manuellement avec des variables d'état locales.
    String? titleError;
    String? amountError;

    // Hauteur de la barre systeme, lue ici et surtout pas dans le
    // StatefulBuilder du sheet : un MediaQuery.of() a l'interieur y enregistre
    // une dependance qui casse la fermeture (voir commentaire plus bas).
    final systemBottomInset = MediaQuery.of(context).padding.bottom;

    final result = await showModalBottomSheet<TodoTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (stCtx, setSheetState) {
            // Pas de MediaQuery.of() ici — adjustResize dans AndroidManifest
            // redimensionne la fenêtre Flutter quand le clavier apparaît, donc
            // le sheet est naturellement repositionné sans padding manuel.
            // Un appel MediaQuery.of(stCtx) dans StatefulBuilder enregistre une
            // dépendance qui cause "_dependents.isEmpty" quand le clavier se
            // cache au moment exact de la fermeture du sheet.
            return Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + systemBottomInset),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      isEdit ? l10n.editTodo : l10n.newTodo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title field
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                          color: textPrimary, fontWeight: FontWeight.w500),
                      decoration: buildDecoration(l10n.description)
                          .copyWith(errorText: titleError),
                    ),
                    const SizedBox(height: 14),

                    // Amount + type toggle
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w500),
                            decoration: buildDecoration(l10n.amount)
                                .copyWith(errorText: amountError),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: inputFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              typeBtn(setSheetState,
                                  value: 'withdrawal',
                                  icon: Icons.arrow_upward_rounded,
                                  color: _red,
                                  selected: selectedType == 'withdrawal',
                                  onTap: () => setSheetState(
                                      () => selectedType = 'withdrawal')),
                              typeBtn(setSheetState,
                                  value: 'deposit',
                                  icon: Icons.arrow_downward_rounded,
                                  color: _green,
                                  selected: selectedType == 'deposit',
                                  onTap: () => setSheetState(
                                      () => selectedType = 'deposit')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDialog<String>(
                          context: context,
                          builder: (_) => SimpleDialog(
                            backgroundColor: card,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text(l10n.category,
                                style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700)),
                            children: categories
                                .map((c) => SimpleDialogOption(
                                      onPressed: () =>
                                          Navigator.pop(context, c.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Text(c.name,
                                            style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 15)),
                                      ),
                                    ))
                                .toList(),
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedCategoryId = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined,
                                size: 18, color: textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.category,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    categories
                                            .where((c) =>
                                                c.id == selectedCategoryId)
                                            .firstOrNull
                                            ?.name ??
                                        '—',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Due date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          final timePicked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          setSheetState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              timePicked?.hour ?? selectedDate.hour,
                              timePicked?.minute ?? selectedDate.minute,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 18, color: textSecondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.dueDate,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500)),
                                Text(_formatDate(context, selectedDate),
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Recurrence chips
                    Text(l10n.recurrence,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        recurrenceChip(setSheetState,
                            label: l10n.recurrenceNone,
                            value: 'none',
                            selected: selectedRecurrence,
                            onTap: () => setSheetState(
                                () => selectedRecurrence = 'none')),
                        const SizedBox(width: 8),
                        recurrenceChip(setSheetState,
                            label: l10n.recurrenceWeekly,
                            value: 'weekly',
                            selected: selectedRecurrence,
                            onTap: () => setSheetState(
                                () => selectedRecurrence = 'weekly')),
                        const SizedBox(width: 8),
                        recurrenceChip(setSheetState,
                            label: l10n.recurrenceMonthly,
                            value: 'monthly',
                            selected: selectedRecurrence,
                            onTap: () => setSheetState(
                                () => selectedRecurrence = 'monthly')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validation manuelle — pas de Form/GlobalKey
                          final titleVal = titleController.text.trim();
                          final amountVal =
                              amountController.text.replaceAll(',', '.');
                          final parsedAmount = double.tryParse(amountVal);

                          final newTitleError = titleVal.isEmpty
                              ? l10n.pleaseEnterDescription
                              : null;
                          final newAmountError = amountVal.isEmpty
                              ? l10n.pleaseEnterAmount
                              : parsedAmount == null
                                  ? l10n.pleaseEnterAmountInvalid
                                  : null;

                          if (newTitleError != null || newAmountError != null) {
                            setSheetState(() {
                              titleError = newTitleError;
                              amountError = newAmountError;
                            });
                            return;
                          }

                          if (context.mounted) {
                            Navigator.pop(
                              context,
                              TodoTask(
                                id: existing?.id,
                                userId: existing?.userId,
                                title: titleVal,
                                amount: parsedAmount!,
                                type: selectedType,
                                categoryId: selectedCategoryId,
                                dueDate: selectedDate,
                                recurrence: selectedRecurrence,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      titleController.dispose();
      amountController.dispose();
    });

    // Sheet fermé — opérations async sans conflit avec le widget tree
    if (!mounted || result == null) return;

    if (isEdit) {
      await SupabaseDataService().updateTodo(result);
      if (existing.id != null) {
        await TodoNotificationService().cancelReminder(existing.id!);
      }
      await TodoNotificationService().scheduleReminder(result);
    } else {
      await SupabaseDataService().addTodo(result);
      final todos = await SupabaseDataService().getTodos();
      final inserted = todos
          .where((t) =>
              t.title == result.title &&
              t.dueDate.isAtSameMomentAs(result.dueDate))
          .firstOrNull;
      if (inserted != null) {
        await TodoNotificationService().scheduleReminder(inserted);
      }
    }
  }
}
