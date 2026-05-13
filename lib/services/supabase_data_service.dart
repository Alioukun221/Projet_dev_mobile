import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/models/budget.dart';
import 'package:spendwise/models/category.dart' as models;
import 'package:spendwise/models/todo_task.dart';
import 'package:spendwise/services/connectivity_service.dart';
import 'package:spendwise/services/local_cache_service.dart';

class SupabaseDataService {
  static final SupabaseDataService _instance = SupabaseDataService._internal();
  factory SupabaseDataService() => _instance;
  SupabaseDataService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  bool get _isOnline => ConnectivityService.instance.isOnline;
  final _cache = LocalCacheService.instance;

  // Stream controllers for reactive UI
  final _transactionsController =
      StreamController<List<Transaction>>.broadcast();
  final _budgetsController = StreamController<List<Budget>>.broadcast();
  final _categoriesController =
      StreamController<List<models.Category>>.broadcast();
  final _todosController = StreamController<List<TodoTask>>.broadcast();

  Stream<List<Transaction>> get transactionsStream =>
      _transactionsController.stream;
  Stream<List<Budget>> get budgetsStream => _budgetsController.stream;
  Stream<List<models.Category>> get categoriesStream =>
      _categoriesController.stream;
  Stream<List<TodoTask>> get todosStream => _todosController.stream;

  bool _initialized = false;
  bool _realtimeActive = false;
  StreamSubscription? _connectivitySub;
  final List<StreamSubscription> _realtimeSubs = [];

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _initConnectivityListener();
    if (_isOnline) {
      _initRealtimeSubscriptions();
    }
    await refreshAll();
  }

  Future<void> refreshAll() async {
    final results = await Future.wait([
      getTransactions(),
      getBudgets(),
      getCategories(),
      getTodos(),
    ]);
    _transactionsController.add(results[0] as List<Transaction>);
    _budgetsController.add(results[1] as List<Budget>);
    _categoriesController.add(results[2] as List<models.Category>);
    _todosController.add(results[3] as List<TodoTask>);
  }

  void _initConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = ConnectivityService.instance.onlineStream.listen((online) async {
      if (online) {
        await _syncPendingOperations();
        _initRealtimeSubscriptions();
      }
    });
  }

  Future<void> _syncPendingOperations() async {
    final ops = _cache.getPendingOps();
    if (ops.isEmpty) return;

    for (final op in ops) {
      try {
        switch (op.action) {
          case 'insert':
            await _client.from(op.table).insert(op.data);
            break;
          case 'update':
            if (op.id != null) {
              await _client.from(op.table).update(op.data).eq('id', op.id!);
            }
            break;
          case 'delete':
            if (op.id != null) {
              await _client.from(op.table).delete().eq('id', op.id!);
            }
            break;
          case 'soft_delete':
            if (op.id != null) {
              await _client.from(op.table).update(op.data).eq('id', op.id!);
            }
            break;
          case 'restore_defaults':
            await _client
                .from('categories')
                .update({'is_deleted': false})
                .eq('user_id', _userId)
                .eq('is_default', true);
            await _client
                .from('categories')
                .delete()
                .eq('user_id', _userId)
                .eq('is_default', false);
            break;
        }
      } catch (e) {
        debugPrint('_syncPendingOperations ${op.table}.${op.action}: $e');
      }
    }
    _cache.clearQueue();
    await refreshAll();
  }

  void _initRealtimeSubscriptions() {
    if (_realtimeActive) return;
    _realtimeActive = true;

    _realtimeSubs.add(
      _client
          .from('transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId)
          .listen((_) async {
        try {
          final data = await getTransactions();
          _transactionsController.add(data);
          // Also refresh budgets since spent may have changed via trigger
          final budgets = await getBudgets();
          _budgetsController.add(budgets);
        } catch (e) { debugPrint('SupabaseDataService realtime: $e'); }
      }),
    );

    _realtimeSubs.add(
      _client
          .from('budgets')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId)
          .listen((_) async {
        try {
          final data = await getBudgets();
          _budgetsController.add(data);
        } catch (e) { debugPrint('SupabaseDataService realtime: $e'); }
      }),
    );

    _realtimeSubs.add(
      _client
          .from('categories')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId)
          .listen((_) async {
        try {
          final data = await getCategories();
          _categoriesController.add(data);
        } catch (e) { debugPrint('SupabaseDataService realtime: $e'); }
      }),
    );

    _realtimeSubs.add(
      _client
          .from('todo_tasks')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId)
          .listen((_) async {
        try {
          final data = await getTodos();
          _todosController.add(data);
        } catch (e) { debugPrint('SupabaseDataService realtime: $e'); }
      }),
    );
  }

  void _cancelRealtimeSubs() {
    for (final sub in _realtimeSubs) {
      sub.cancel();
    }
    _realtimeSubs.clear();
    _realtimeActive = false;
  }

  void reset() {
    _cancelRealtimeSubs();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _initialized = false;
  }

  void dispose() {
    _cancelRealtimeSubs();
    _connectivitySub?.cancel();
    _transactionsController.close();
    _budgetsController.close();
    _categoriesController.close();
    _todosController.close();
  }

  // ============ CATEGORIES ============

  Future<List<models.Category>> getCategories() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('categories')
            .select()
            .eq('user_id', _userId)
            .eq('is_deleted', false)
            .order('name');
        _cache.cacheCategories(response);
        return (response as List)
            .map((json) => models.Category.fromJson(json))
            .toList();
      } catch (e) {
        debugPrint('SupabaseDataService.getCategories: $e');
        return _getCachedCategories();
      }
    }
    return _getCachedCategories();
  }

  List<models.Category> _getCachedCategories() {
    return _cache
        .getCachedCategories()
        .where((json) => json['is_deleted'] != true)
        .map((json) => models.Category.fromJson(json))
        .toList();
  }

  Future<List<String>> getAllCategoryNames() async {
    final categories = await getCategories();
    return categories.map((c) => c.name).toList()..sort();
  }

  Future<bool> categoryExists(String name) async {
    final categories = await getCategories();
    return categories.any(
        (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  Future<void> addCategory(models.Category category) async {
    final data = {'user_id': _userId, ...category.toJson()};
    if (_isOnline) {
      try {
        await _client.from('categories').insert(data);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(table: 'categories', action: 'insert', data: data));
      }
    } else {
      _cache.enqueue(SyncOperation(table: 'categories', action: 'insert', data: data));
    }
    await _refreshCategories();
  }

  Future<void> updateCategory(models.Category category) async {
    if (category.id == null) throw Exception('Category has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('categories')
            .update(category.toJson())
            .eq('id', category.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'categories', action: 'update', data: category.toJson(), id: category.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'categories', action: 'update', data: category.toJson(), id: category.id,
      ));
    }
    await _refreshCategories();
  }

  Future<void> deleteCategory(models.Category category) async {
    if (category.id == null) throw Exception('Category has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('categories')
            .update({'is_deleted': true})
            .eq('id', category.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'categories', action: 'soft_delete', data: {'is_deleted': true}, id: category.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'categories', action: 'soft_delete', data: {'is_deleted': true}, id: category.id,
      ));
    }
    await _refreshCategories();
  }

  Future<void> restoreDefaultCategories() async {
    if (_isOnline) {
      try {
        await _client
            .from('categories')
            .update({'is_deleted': false})
            .eq('user_id', _userId)
            .eq('is_default', true);
        await _client
            .from('categories')
            .delete()
            .eq('user_id', _userId)
            .eq('is_default', false);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'categories', action: 'restore_defaults', data: {},
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'categories', action: 'restore_defaults', data: {},
      ));
    }
    await _refreshCategories();
  }

  Future<String?> getCategoryIdByName(String name) async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('categories')
            .select('id')
            .eq('user_id', _userId)
            .eq('name', name)
            .eq('is_deleted', false)
            .maybeSingle();
        return response?['id'] as String?;
      } catch (e) {
        debugPrint('SupabaseDataService.getCategoryIdByName: $e');
        return _getCachedCategoryIdByName(name);
      }
    }
    return _getCachedCategoryIdByName(name);
  }

  String? _getCachedCategoryIdByName(String name) {
    final categories = _cache.getCachedCategories();
    for (final c in categories) {
      if (c['name'] == name && c['is_deleted'] != true) {
        return c['id'] as String?;
      }
    }
    return null;
  }

  // ============ TRANSACTIONS ============

  Future<List<Transaction>> getTransactions() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('transactions')
            .select('*, categories(name)')
            .eq('user_id', _userId)
            .order('date', ascending: false);
        _cache.cacheTransactions(response);
        return (response as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
      } catch (e) {
        debugPrint('SupabaseDataService.getTransactions: $e');
        return _getCachedTransactions();
      }
    }
    return _getCachedTransactions();
  }

  List<Transaction> _getCachedTransactions() {
    return _cache
        .getCachedTransactions()
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final data = {'user_id': _userId, ...transaction.toJson()};
    if (_isOnline) {
      try {
        await _client.from('transactions').insert(data);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(table: 'transactions', action: 'insert', data: data));
      }
    } else {
      _cache.enqueue(SyncOperation(table: 'transactions', action: 'insert', data: data));
    }
    await _refreshTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Transaction has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('transactions')
            .update(transaction.toJson())
            .eq('id', transaction.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'transactions', action: 'update', data: transaction.toJson(), id: transaction.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'transactions', action: 'update', data: transaction.toJson(), id: transaction.id,
      ));
    }
    await _refreshTransactions();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Transaction has no ID');
    if (_isOnline) {
      try {
        await _client.from('transactions').delete().eq('id', transaction.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'transactions', action: 'delete', data: {}, id: transaction.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'transactions', action: 'delete', data: {}, id: transaction.id,
      ));
    }
    await _refreshTransactions();
  }

  // ============ BUDGETS ============

  Future<List<Budget>> getBudgets() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('budgets')
            .select('*, categories(name)')
            .eq('user_id', _userId)
            .order('start_date', ascending: false);
        _cache.cacheBudgets(response);
        return (response as List).map((json) => Budget.fromJson(json)).toList();
      } catch (e) {
        debugPrint('SupabaseDataService.getBudgets: $e');
        return _getCachedBudgets();
      }
    }
    return _getCachedBudgets();
  }

  List<Budget> _getCachedBudgets() {
    return _cache
        .getCachedBudgets()
        .map((json) => Budget.fromJson(json))
        .toList();
  }

  Future<void> addBudget(Budget budget) async {
    final data = {'user_id': _userId, ...budget.toJson()};
    if (_isOnline) {
      try {
        await _client.from('budgets').insert(data);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(table: 'budgets', action: 'insert', data: data));
      }
    } else {
      _cache.enqueue(SyncOperation(table: 'budgets', action: 'insert', data: data));
    }
    await _refreshBudgets();
  }

  Future<void> updateBudget(Budget budget) async {
    if (budget.id == null) throw Exception('Budget has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('budgets')
            .update(budget.toJson())
            .eq('id', budget.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'budgets', action: 'update', data: budget.toJson(), id: budget.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'budgets', action: 'update', data: budget.toJson(), id: budget.id,
      ));
    }
    await _refreshBudgets();
  }

  Future<void> deleteBudget(Budget budget) async {
    if (budget.id == null) throw Exception('Budget has no ID');
    if (_isOnline) {
      try {
        await _client.from('budgets').delete().eq('id', budget.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'budgets', action: 'delete', data: {}, id: budget.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'budgets', action: 'delete', data: {}, id: budget.id,
      ));
    }
    await _refreshBudgets();
  }

  // ============ REFRESH HELPERS ============

  Future<void> _refreshTransactions() async {
    final data = await getTransactions();
    _transactionsController.add(data);
    // Also refresh budgets since spent may change
    final budgets = await getBudgets();
    _budgetsController.add(budgets);
  }

  Future<void> _refreshBudgets() async {
    final data = await getBudgets();
    _budgetsController.add(data);
  }

  Future<void> _refreshCategories() async {
    final data = await getCategories();
    _categoriesController.add(data);
  }

  Future<void> _refreshTodos() async {
    final data = await getTodos();
    _todosController.add(data);
  }

  // ============ TODOS ============

  Future<List<TodoTask>> getTodos() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('todo_tasks')
            .select('*, categories(name)')
            .eq('user_id', _userId)
            .eq('is_completed', false)
            .order('due_date');
        _cache.cacheTodos(response);
        return (response as List).map((json) => TodoTask.fromJson(json)).toList();
      } catch (e) {
        debugPrint('SupabaseDataService.getTodos: $e');
        return _getCachedTodos();
      }
    }
    return _getCachedTodos();
  }

  List<TodoTask> _getCachedTodos() {
    return _cache
        .getCachedTodos()
        .where((json) => json['is_completed'] != true)
        .map((json) => TodoTask.fromJson(json))
        .toList();
  }

  Future<void> addTodo(TodoTask todo) async {
    final data = {'user_id': _userId, ...todo.toJson()};
    if (_isOnline) {
      try {
        await _client.from('todo_tasks').insert(data);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(table: 'todo_tasks', action: 'insert', data: data));
      }
    } else {
      _cache.enqueue(SyncOperation(table: 'todo_tasks', action: 'insert', data: data));
    }
    await _refreshTodos();
  }

  Future<void> updateTodo(TodoTask todo) async {
    if (todo.id == null) throw Exception('Todo has no ID');
    if (_isOnline) {
      try {
        await _client.from('todo_tasks').update(todo.toJson()).eq('id', todo.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'todo_tasks', action: 'update', data: todo.toJson(), id: todo.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'todo_tasks', action: 'update', data: todo.toJson(), id: todo.id,
      ));
    }
    await _refreshTodos();
  }

  Future<void> deleteTodo(TodoTask todo) async {
    if (todo.id == null) throw Exception('Todo has no ID');
    if (_isOnline) {
      try {
        await _client.from('todo_tasks').delete().eq('id', todo.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'todo_tasks', action: 'delete', data: {}, id: todo.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'todo_tasks', action: 'delete', data: {}, id: todo.id,
      ));
    }
    await _refreshTodos();
  }

  /// Marks a todo as completed, creates a transaction, and schedules the next
  /// occurrence if recurrent. Returns the newly created TodoTask (next occurrence)
  /// if applicable, otherwise null.
  Future<TodoTask?> completeTodo(TodoTask todo, {double? adjustedAmount}) async {
    if (todo.id == null) throw Exception('Todo has no ID');

    final amount = adjustedAmount ?? todo.amount;
    final now = DateTime.now();

    // 1. Create transaction
    String? newTransactionId;
    final txData = {
      'user_id': _userId,
      'type': todo.type,
      'amount': amount,
      'description': todo.title,
      'date': now.toIso8601String(),
      'category_id': todo.categoryId,
    };
    if (_isOnline) {
      try {
        final txResponse =
            await _client.from('transactions').insert(txData).select('id').single();
        newTransactionId = txResponse['id'] as String?;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(table: 'transactions', action: 'insert', data: txData));
      }
    } else {
      _cache.enqueue(SyncOperation(table: 'transactions', action: 'insert', data: txData));
    }

    // 2. Mark todo as completed
    final completedData = {
      'is_completed': true,
      'completed_at': now.toIso8601String(),
      if (newTransactionId != null) 'transaction_id': newTransactionId,
    };
    if (_isOnline) {
      try {
        await _client.from('todo_tasks').update(completedData).eq('id', todo.id!);
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        _cache.enqueue(SyncOperation(
          table: 'todo_tasks', action: 'update', data: completedData, id: todo.id,
        ));
      }
    } else {
      _cache.enqueue(SyncOperation(
        table: 'todo_tasks', action: 'update', data: completedData, id: todo.id,
      ));
    }

    // 3. Create next occurrence if recurrent
    TodoTask? nextTodo;
    if (todo.recurrence != 'none') {
      final DateTime nextDueDate = todo.recurrence == 'weekly'
          ? todo.dueDate.add(const Duration(days: 7))
          : DateTime(
              todo.dueDate.year,
              todo.dueDate.month + 1,
              todo.dueDate.day,
              todo.dueDate.hour,
              todo.dueDate.minute,
            );

      nextTodo = TodoTask(
        userId: _userId,
        title: todo.title,
        amount: todo.amount,
        type: todo.type,
        categoryId: todo.categoryId,
        dueDate: nextDueDate,
        recurrence: todo.recurrence,
      );

      final nextData = {'user_id': _userId, ...nextTodo.toJson()};
      if (_isOnline) {
        try {
          final nextResponse =
              await _client.from('todo_tasks').insert(nextData).select('id').single();
          nextTodo = TodoTask(
            id: nextResponse['id'] as String?,
            userId: _userId,
            title: todo.title,
            amount: todo.amount,
            type: todo.type,
            categoryId: todo.categoryId,
            dueDate: nextDueDate,
            recurrence: todo.recurrence,
          );
        } catch (e) {
          _cache.enqueue(SyncOperation(table: 'todo_tasks', action: 'insert', data: nextData));
        }
      } else {
        _cache.enqueue(SyncOperation(table: 'todo_tasks', action: 'insert', data: nextData));
      }
    }

    await Future.wait([_refreshTodos(), _refreshTransactions()]);
    return nextTodo;
  }
}
