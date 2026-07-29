import 'dart:async';
import 'dart:math';
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

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('SupabaseDataService: no authenticated user');
    }
    return id;
  }

  bool get _isOnline => ConnectivityService.instance.isOnline;
  final _cache = LocalCacheService.instance;

  // Stream controllers for reactive UI
  final _transactionsController =
      StreamController<List<Transaction>>.broadcast();
  final _budgetsController = StreamController<List<Budget>>.broadcast();
  final _categoriesController =
      StreamController<List<models.Category>>.broadcast();
  final _todosController = StreamController<List<TodoTask>>.broadcast();
  final _syncResultController = StreamController<String>.broadcast();

  static const _transactionSelect = '*, categories(name)';
  static const _budgetSelect = '*, categories(name)';
  static const _todoSelect = '*, categories(name)';

  // Cached last values — replayed to new subscribers (fixes broadcast no-replay)
  List<Transaction> _lastTransactions = [];
  List<Budget> _lastBudgets = [];
  List<models.Category> _lastCategories = [];
  List<TodoTask> _lastTodos = [];

  Stream<List<Transaction>> get transactionsStream =>
      _seeded(_transactionsController.stream, _lastTransactions);
  Stream<List<Budget>> get budgetsStream =>
      _seeded(_budgetsController.stream, _lastBudgets);
  Stream<List<models.Category>> get categoriesStream =>
      _seeded(_categoriesController.stream, _lastCategories);
  Stream<List<TodoTask>> get todosStream =>
      _seeded(_todosController.stream, _lastTodos);
  Stream<String> get syncResultStream => _syncResultController.stream;

  /// Returns a stream that immediately emits [seed] to new subscribers,
  /// then forwards all subsequent events from [source].
  Stream<T> _seeded<T>(Stream<T> source, T seed) => Stream.multi((controller) {
        controller.add(seed);
        final sub = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = sub.cancel;
      });

  void _emitTransactions(List<Transaction> data) {
    _lastTransactions = data;
    _transactionsController.add(data);
  }

  void _emitBudgets(List<Budget> data) {
    _lastBudgets = data;
    _budgetsController.add(data);
  }

  void _emitCategories(List<models.Category> data) {
    _lastCategories = data;
    _categoriesController.add(data);
  }

  void _emitTodos(List<TodoTask> data) {
    _lastTodos = data;
    _todosController.add(data);
  }

  bool _initialized = false;
  bool _realtimeActive = false;
  bool _hasFirstLoad = false;
  bool _syncInProgress = false;
  bool _syncAgainRequested = false;
  StreamSubscription? _connectivitySub;
  final List<StreamSubscription> _realtimeSubs = [];

  bool get isFirstLoadComplete => _hasFirstLoad;

  Future<void> init() async {
    if (_initialized) return;
    await _cache.setActiveUser(_userId);
    _initialized = true;
    _initConnectivityListener();
    if (_isOnline) {
      await _syncPendingOperations(refreshAfterSync: false);
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
    _lastTransactions = results[0] as List<Transaction>;
    _lastBudgets = results[1] as List<Budget>;
    _lastCategories = results[2] as List<models.Category>;
    _lastTodos = results[3] as List<TodoTask>;
    _emitTransactions(_lastTransactions);
    _emitBudgets(_lastBudgets);
    _emitCategories(_lastCategories);
    _emitTodos(_lastTodos);
    _hasFirstLoad = true;
  }

  void _initConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub =
        ConnectivityService.instance.onlineStream.listen((online) async {
      if (online) {
        await _syncPendingOperations();
        _initRealtimeSubscriptions();
      }
    });
  }

  Future<void> _syncPendingOperations({bool refreshAfterSync = true}) async {
    if (_syncInProgress) {
      _syncAgainRequested = true;
      return;
    }

    _syncInProgress = true;
    var didWork = false;
    try {
      do {
        _syncAgainRequested = false;
        final ops = _cache.getPendingOps();
        if (ops.isEmpty) break;

        didWork = true;
        final failedOps = <SyncOperation>[];
        for (final op in ops) {
          try {
            switch (op.action) {
              case 'insert':
                await _client.from(op.table).upsert(op.data);
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
            failedOps.add(op);
          }
        }
        await _cache.clearQueue();
        for (final op in failedOps) {
          await _cache.enqueue(op);
        }
        if (failedOps.isNotEmpty) {
          _syncResultController.add('partial_failure:${failedOps.length}');
        }
      } while (_syncAgainRequested);
    } finally {
      _syncInProgress = false;
    }

    if (didWork && refreshAfterSync) {
      await refreshAll();
    }
  }

  void _schedulePendingSync() {
    if (!_initialized || !_isOnline || !_cache.hasPendingOps) return;
    Future.microtask(() => _syncPendingOperations());
  }

  void _initRealtimeSubscriptions() {
    if (_realtimeActive) return;
    try {
      final uid = _userId; // throws StateError if not authenticated
      _realtimeSubs.add(
        _client
            .from('transactions')
            .stream(primaryKey: ['id'])
            .eq('user_id', uid)
            .listen(
              (_) async {
                try {
                  final data = await getTransactions();
                  _emitTransactions(data);
                } catch (e) {
                  debugPrint('[SDS] realtime tx data: $e');
                }
              },
              onError: (e) => _handleRealtimeError('transactions', e),
            ),
      );

      _realtimeSubs.add(
        _client
            .from('budgets')
            .stream(primaryKey: ['id'])
            .eq('user_id', uid)
            .listen(
              (_) async {
                try {
                  final data = await getBudgets();
                  _emitBudgets(data);
                } catch (e) {
                  debugPrint('[SDS] realtime budgets data: $e');
                }
              },
              onError: (e) => _handleRealtimeError('budgets', e),
            ),
      );

      _realtimeSubs.add(
        _client
            .from('categories')
            .stream(primaryKey: ['id'])
            .eq('user_id', uid)
            .listen(
              (_) async {
                try {
                  final data = await getCategories();
                  _emitCategories(data);
                } catch (e) {
                  debugPrint('[SDS] realtime categories data: $e');
                }
              },
              onError: (e) => _handleRealtimeError('categories', e),
            ),
      );

      _realtimeSubs.add(
        _client
            .from('todo_tasks')
            .stream(primaryKey: ['id'])
            .eq('user_id', uid)
            .listen(
              (_) async {
                try {
                  final data = await getTodos();
                  _emitTodos(data);
                } catch (e) {
                  debugPrint('[SDS] realtime todos data: $e');
                }
              },
              onError: (e) => _handleRealtimeError('todo_tasks', e),
            ),
      );

      _realtimeActive = true; // flag set only after all subs succeed
    } catch (e) {
      debugPrint('[SDS] _initRealtimeSubscriptions failed: $e');
      _cancelRealtimeSubs();
    }
  }

  bool _realtimeRetryScheduled = false;

  void _handleRealtimeError(String table, Object error) {
    debugPrint('[SDS] realtime $table error: $error — cancelling all subs');
    _cancelRealtimeSubs(); // resets _realtimeActive = false
    // Refresh data via REST so UI doesn't go stale
    refreshAll().catchError(
        (e) => debugPrint('[SDS] refreshAll after realtime error: $e'));
    // Schedule a single retry (30s) — skip if one already pending
    if (_realtimeRetryScheduled || !_initialized) return;
    _realtimeRetryScheduled = true;
    Future.delayed(const Duration(seconds: 30), () {
      _realtimeRetryScheduled = false;
      if (_initialized && _isOnline) {
        debugPrint('[SDS] retrying realtime subscriptions');
        _initRealtimeSubscriptions();
      }
    });
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
    _hasFirstLoad = false;
    _realtimeRetryScheduled = false;
    _syncInProgress = false;
    _syncAgainRequested = false;
    _lastTransactions = [];
    _lastBudgets = [];
    _lastCategories = [];
    _lastTodos = [];
    _cache.detachActiveUser();
    debugPrint('[SDS] reset — caches cleared');
  }

  void dispose() {
    _cancelRealtimeSubs();
    _connectivitySub?.cancel();
    _transactionsController.close();
    _budgetsController.close();
    _categoriesController.close();
    _todosController.close();
    _syncResultController.close();
  }

  List<Map<String, dynamic>> _mergePendingRows(
    String table,
    List<dynamic> serverRows,
  ) {
    final rowsById = <String, Map<String, dynamic>>{};
    final rowsWithoutId = <Map<String, dynamic>>[];

    for (final raw in serverRows) {
      final row =
          _augmentRowForTable(table, Map<String, dynamic>.from(raw as Map));
      final id = row['id']?.toString();
      if (id == null) {
        rowsWithoutId.add(row);
      } else {
        rowsById[id] = row;
      }
    }

    final cachedRowsById = <String, Map<String, dynamic>>{};
    for (final row in _cachedRowsForTable(table)) {
      final id = row['id']?.toString();
      if (id != null) cachedRowsById[id] = row;
    }

    for (final op in _cache.getPendingOps().where((op) => op.table == table)) {
      switch (op.action) {
        case 'insert':
          final row = _augmentRowForTable(
            table,
            Map<String, dynamic>.from(op.data),
          );
          final id = row['id']?.toString();
          if (id == null) {
            rowsWithoutId.add(row);
          } else {
            rowsById[id] = {
              ...?cachedRowsById[id],
              ...?rowsById[id],
              ...row,
            };
          }
          break;
        case 'update':
        case 'soft_delete':
          final id = op.id;
          if (id == null) break;
          final base = <String, dynamic>{
            ...?cachedRowsById[id],
            ...?rowsById[id],
            'id': id,
          };
          rowsById[id] = _augmentRowForTable(table, {
            ...base,
            ...op.data,
          });
          break;
        case 'delete':
          final id = op.id;
          if (id != null) rowsById.remove(id);
          break;
        case 'restore_defaults':
          if (table == 'categories') {
            final restored = <String, Map<String, dynamic>>{};
            for (final row in rowsById.values) {
              if (row['is_default'] == true) {
                final id = row['id']?.toString();
                if (id != null) restored[id] = {...row, 'is_deleted': false};
              }
            }
            rowsById
              ..clear()
              ..addAll(restored);
          }
          break;
      }
    }

    return _sortRowsForTable(table, [
      ...rowsById.values,
      ...rowsWithoutId,
    ]).where((row) {
      if (table == 'categories') return row['is_deleted'] != true;
      if (table == 'todo_tasks') return row['is_completed'] != true;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _cachedRowsForTable(String table) {
    switch (table) {
      case 'transactions':
        return _cache.getCachedTransactions();
      case 'budgets':
        return _cache.getCachedBudgets();
      case 'categories':
        return _cache.getCachedCategories();
      case 'todo_tasks':
        return _cache.getCachedTodos();
      default:
        return const [];
    }
  }

  Map<String, dynamic> _augmentRowForTable(
    String table,
    Map<String, dynamic> row,
  ) {
    if ((table == 'transactions' ||
            table == 'budgets' ||
            table == 'todo_tasks') &&
        row['categories'] == null) {
      final categoryName = _categoryNameById(row['category_id'] as String?);
      if (categoryName != null) {
        row['categories'] = {'name': categoryName};
      }
    }
    if (table == 'budgets') {
      row.putIfAbsent('spent', () => 0);
    }
    if (table == 'categories') {
      row.putIfAbsent('is_default', () => false);
      row.putIfAbsent('is_deleted', () => false);
    }
    if (table == 'todo_tasks') {
      row.putIfAbsent('recurrence', () => 'none');
      row.putIfAbsent('is_completed', () => false);
    }
    return row;
  }

  String? _categoryNameById(String? categoryId) {
    if (categoryId == null) return null;
    for (final category in _cache.getCachedCategories()) {
      if (category['id'] == categoryId && category['is_deleted'] != true) {
        return category['name'] as String?;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _sortRowsForTable(
    String table,
    List<Map<String, dynamic>> rows,
  ) {
    final sorted = List<Map<String, dynamic>>.from(rows);
    switch (table) {
      case 'transactions':
        sorted.sort((a, b) => _compareDateDesc(a['date'], b['date']));
        break;
      case 'budgets':
        sorted
            .sort((a, b) => _compareDateDesc(a['start_date'], b['start_date']));
        break;
      case 'categories':
        sorted.sort((a, b) => (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? ''));
        break;
      case 'todo_tasks':
        sorted.sort((a, b) => _compareDateAsc(a['due_date'], b['due_date']));
        break;
    }
    return sorted;
  }

  int _compareDateDesc(dynamic a, dynamic b) {
    final aDate = DateTime.tryParse(a?.toString() ?? '');
    final bDate = DateTime.tryParse(b?.toString() ?? '');
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }

  int _compareDateAsc(dynamic a, dynamic b) {
    final aDate = DateTime.tryParse(a?.toString() ?? '');
    final bDate = DateTime.tryParse(b?.toString() ?? '');
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  Map<String, dynamic> _transactionCacheData(
    Transaction transaction, {
    String? id,
  }) {
    return _augmentRowForTable('transactions', {
      if ((id ?? transaction.id) != null) 'id': id ?? transaction.id,
      'user_id': transaction.userId ?? _userId,
      ...transaction.toJson(),
    });
  }

  Map<String, dynamic> _budgetCacheData(Budget budget, {String? id}) {
    return _augmentRowForTable('budgets', {
      if ((id ?? budget.id) != null) 'id': id ?? budget.id,
      'user_id': budget.userId ?? _userId,
      'spent': budget.spent,
      ...budget.toJson(),
    });
  }

  Map<String, dynamic> _categoryCacheData(models.Category category,
      {String? id}) {
    return _augmentRowForTable('categories', {
      if ((id ?? category.id) != null) 'id': id ?? category.id,
      'user_id': category.userId ?? _userId,
      ...category.toJson(),
    });
  }

  Map<String, dynamic> _todoCacheData(TodoTask todo, {String? id}) {
    return _augmentRowForTable('todo_tasks', {
      if ((id ?? todo.id) != null) 'id': id ?? todo.id,
      'user_id': todo.userId ?? _userId,
      ...todo.toJson(),
    });
  }

  Future<void> _emitTransactionsFromCache({bool refreshBudgets = false}) async {
    _emitTransactions(_getCachedTransactions());
    if (refreshBudgets) {
      await _refreshBudgets();
    }
  }

  void _emitBudgetsFromCache() => _emitBudgets(_getCachedBudgets());
  void _emitCategoriesFromCache() => _emitCategories(_getCachedCategories());
  void _emitTodosFromCache() => _emitTodos(_getCachedTodos());

  List<Map<String, dynamic>> _applyLocalBudgetSpent(
    List<Map<String, dynamic>> budgetRows,
  ) {
    final transactionRows =
        _mergePendingRows('transactions', _cache.getCachedTransactions());
    if (transactionRows.isEmpty) {
      return budgetRows;
    }

    return budgetRows.map((budget) {
      final categoryId = budget['category_id']?.toString();
      final startDate =
          DateTime.tryParse(budget['start_date']?.toString() ?? '');
      final endDate = DateTime.tryParse(budget['end_date']?.toString() ?? '');
      if (categoryId == null || startDate == null || endDate == null) {
        return budget;
      }

      var spent = 0.0;
      for (final tx in transactionRows) {
        if (tx['type'] != 'withdrawal') continue;
        if (tx['category_id']?.toString() != categoryId) continue;
        final txDate = DateTime.tryParse(tx['date']?.toString() ?? '');
        if (txDate == null) continue;
        final inRange =
            (txDate.isAtSameMomentAs(startDate) || txDate.isAfter(startDate)) &&
                (txDate.isAtSameMomentAs(endDate) || txDate.isBefore(endDate));
        if (!inRange) continue;
        spent += (tx['amount'] as num).toDouble();
      }
      return {...budget, 'spent': spent};
    }).toList();
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
        final rows = _mergePendingRows('categories', response);
        _cache.cacheCategories(rows);
        return rows.map((json) => models.Category.fromJson(json)).toList();
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
    return categories
        .any((c) => c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  Future<void> addCategory(models.Category category) async {
    final data = {'user_id': _userId, ...category.toJson()};
    if (_isOnline) {
      try {
        final response =
            await _client.from('categories').insert(data).select().single();
        _cache.addCategoryToCache(Map<String, dynamic>.from(response));
        _emitCategoriesFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    final offlineId = category.id ?? _generateUuid();
    final offlineData = {'id': offlineId, ...data};
    await _cache.enqueue(
      SyncOperation(table: 'categories', action: 'insert', data: offlineData),
    );
    _cache.addCategoryToCache(_categoryCacheData(category, id: offlineId));
    _emitCategoriesFromCache();
    _schedulePendingSync();
  }

  Future<void> updateCategory(models.Category category) async {
    if (category.id == null) throw Exception('Category has no ID');
    if (_isOnline) {
      try {
        final response = await _client
            .from('categories')
            .update(category.toJson())
            .eq('id', category.id!)
            .eq('user_id', _userId)
            .select()
            .single();
        _cache.updateCategoryInCache(Map<String, dynamic>.from(response));
        _emitCategoriesFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'categories',
      action: 'update',
      data: category.toJson(),
      id: category.id,
    ));
    _cache.updateCategoryInCache(_categoryCacheData(category));
    _emitCategoriesFromCache();
    _schedulePendingSync();
  }

  Future<void> deleteCategory(models.Category category) async {
    if (category.id == null) throw Exception('Category has no ID');
    if (_isOnline) {
      try {
        final response = await _client
            .from('categories')
            .update({'is_deleted': true})
            .eq('id', category.id!)
            .eq('user_id', _userId)
            .select()
            .single();
        _cache.updateCategoryInCache(Map<String, dynamic>.from(response));
        _emitCategoriesFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'categories',
      action: 'soft_delete',
      data: {'is_deleted': true},
      id: category.id,
    ));
    _cache.updateCategoryInCache({
      ..._categoryCacheData(category),
      'is_deleted': true,
    });
    _emitCategoriesFromCache();
    _schedulePendingSync();
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
        await _refreshCategories();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'categories',
      action: 'restore_defaults',
      data: {},
    ));
    final restoredDefaults = _cache
        .getCachedCategories()
        .where((category) => category['is_default'] == true)
        .map((category) => {...category, 'is_deleted': false})
        .toList();
    _cache.cacheCategories(restoredDefaults);
    _emitCategoriesFromCache();
    _schedulePendingSync();
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
        return response?['id'] as String? ?? _getCachedCategoryIdByName(name);
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

  static String _generateUuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  // ============ TRANSACTIONS ============

  Future<List<Transaction>> getTransactionsPaginated({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_isOnline && !_cache.hasPendingOps) {
      try {
        final response = await _client
            .from('transactions')
            .select(_transactionSelect)
            .eq('user_id', _userId)
            .order('date', ascending: false)
            .range(offset, offset + limit - 1);
        return (response as List)
            .map((json) =>
                Transaction.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
      } catch (e) {
        debugPrint('SupabaseDataService.getTransactionsPaginated: $e');
      }
    }
    final transactions = await getTransactions();
    return transactions.skip(offset).take(limit).toList();
  }

  Future<List<Transaction>> getTransactions() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('transactions')
            .select(_transactionSelect)
            .eq('user_id', _userId)
            .order('date', ascending: false);
        final rows = _mergePendingRows('transactions', response);
        _cache.cacheTransactions(rows);
        return rows.map((json) => Transaction.fromJson(json)).toList();
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
        final response = await _client
            .from('transactions')
            .insert(data)
            .select(_transactionSelect)
            .single();
        _cache.addTransactionToCache(Map<String, dynamic>.from(response));
        await _emitTransactionsFromCache(refreshBudgets: true);
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    final offlineId = transaction.id ?? _generateUuid();
    final offlineData = {'id': offlineId, ...data};
    await _cache.enqueue(
      SyncOperation(table: 'transactions', action: 'insert', data: offlineData),
    );
    _cache.addTransactionToCache(
        _transactionCacheData(transaction, id: offlineId));
    await _emitTransactionsFromCache(refreshBudgets: true);
    _schedulePendingSync();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Transaction has no ID');
    if (_isOnline) {
      try {
        final response = await _client
            .from('transactions')
            .update(transaction.toJson())
            .eq('id', transaction.id!)
            .eq('user_id', _userId)
            .select(_transactionSelect)
            .single();
        _cache.updateTransactionInCache(Map<String, dynamic>.from(response));
        await _emitTransactionsFromCache(refreshBudgets: true);
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'transactions',
      action: 'update',
      data: transaction.toJson(),
      id: transaction.id,
    ));
    _cache.updateTransactionInCache(_transactionCacheData(transaction));
    await _emitTransactionsFromCache(refreshBudgets: true);
    _schedulePendingSync();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Transaction has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('transactions')
            .delete()
            .eq('id', transaction.id!)
            .eq('user_id', _userId);
        _cache.removeTransactionFromCache(transaction.id!);
        await _emitTransactionsFromCache(refreshBudgets: true);
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'transactions',
      action: 'delete',
      data: {},
      id: transaction.id,
    ));
    _cache.removeTransactionFromCache(transaction.id!);
    await _emitTransactionsFromCache(refreshBudgets: true);
    _schedulePendingSync();
  }

  // ============ BUDGETS ============

  Future<List<Budget>> getBudgets() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('budgets')
            .select(_budgetSelect)
            .eq('user_id', _userId)
            .order('start_date', ascending: false);
        final rows =
            _applyLocalBudgetSpent(_mergePendingRows('budgets', response));
        _cache.cacheBudgets(rows);
        return rows.map((json) => Budget.fromJson(json)).toList();
      } catch (e) {
        debugPrint('SupabaseDataService.getBudgets: $e');
        return _getCachedBudgets();
      }
    }
    return _getCachedBudgets();
  }

  List<Budget> _getCachedBudgets() {
    final rows = _applyLocalBudgetSpent(_cache.getCachedBudgets());
    _cache.cacheBudgets(rows);
    return rows.map((json) => Budget.fromJson(json)).toList();
  }

  Future<void> addBudget(Budget budget) async {
    final data = {'user_id': _userId, ...budget.toJson()};
    if (_isOnline) {
      try {
        final response = await _client
            .from('budgets')
            .insert(data)
            .select(_budgetSelect)
            .single();
        _cache.addBudgetToCache(Map<String, dynamic>.from(response));
        _emitBudgetsFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    final offlineId = budget.id ?? _generateUuid();
    final offlineData = {'id': offlineId, ...data};
    await _cache.enqueue(
      SyncOperation(table: 'budgets', action: 'insert', data: offlineData),
    );
    _cache.addBudgetToCache(_budgetCacheData(budget, id: offlineId));
    _emitBudgetsFromCache();
    _schedulePendingSync();
  }

  Future<void> updateBudget(Budget budget) async {
    if (budget.id == null) throw Exception('Budget has no ID');
    if (_isOnline) {
      try {
        final response = await _client
            .from('budgets')
            .update(budget.toJson())
            .eq('id', budget.id!)
            .eq('user_id', _userId)
            .select(_budgetSelect)
            .single();
        _cache.updateBudgetInCache(Map<String, dynamic>.from(response));
        _emitBudgetsFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'budgets',
      action: 'update',
      data: budget.toJson(),
      id: budget.id,
    ));
    _cache.updateBudgetInCache(_budgetCacheData(budget));
    _emitBudgetsFromCache();
    _schedulePendingSync();
  }

  Future<void> deleteBudget(Budget budget) async {
    if (budget.id == null) throw Exception('Budget has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('budgets')
            .delete()
            .eq('id', budget.id!)
            .eq('user_id', _userId);
        _cache.removeBudgetFromCache(budget.id!);
        _emitBudgetsFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'budgets',
      action: 'delete',
      data: {},
      id: budget.id,
    ));
    _cache.removeBudgetFromCache(budget.id!);
    _emitBudgetsFromCache();
    _schedulePendingSync();
  }

  // ============ REFRESH HELPERS ============

  Future<void> _refreshBudgets() async {
    final data = await getBudgets();
    _emitBudgets(data);
  }

  Future<void> _refreshCategories() async {
    final data = await getCategories();
    _emitCategories(data);
  }

  // ============ TODOS ============

  Future<List<TodoTask>> getTodos() async {
    if (_isOnline) {
      try {
        final response = await _client
            .from('todo_tasks')
            .select(_todoSelect)
            .eq('user_id', _userId)
            .eq('is_completed', false)
            .order('due_date');
        final rows = _mergePendingRows('todo_tasks', response);
        _cache.cacheTodos(rows);
        return rows.map((json) => TodoTask.fromJson(json)).toList();
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
        final response = await _client
            .from('todo_tasks')
            .insert(data)
            .select(_todoSelect)
            .single();
        _cache.addTodoToCache(Map<String, dynamic>.from(response));
        _emitTodosFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    final offlineId = todo.id ?? _generateUuid();
    final offlineData = {'id': offlineId, ...data};
    await _cache.enqueue(
      SyncOperation(table: 'todo_tasks', action: 'insert', data: offlineData),
    );
    _cache.addTodoToCache(_todoCacheData(todo, id: offlineId));
    _emitTodosFromCache();
    _schedulePendingSync();
  }

  Future<void> updateTodo(TodoTask todo) async {
    if (todo.id == null) throw Exception('Todo has no ID');
    if (_isOnline) {
      try {
        final response = await _client
            .from('todo_tasks')
            .update(todo.toJson())
            .eq('id', todo.id!)
            .eq('user_id', _userId)
            .select(_todoSelect)
            .single();
        _cache.updateTodoInCache(Map<String, dynamic>.from(response));
        _emitTodosFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'todo_tasks',
      action: 'update',
      data: todo.toJson(),
      id: todo.id,
    ));
    _cache.updateTodoInCache(_todoCacheData(todo));
    _emitTodosFromCache();
    _schedulePendingSync();
  }

  Future<void> deleteTodo(TodoTask todo) async {
    if (todo.id == null) throw Exception('Todo has no ID');
    if (_isOnline) {
      try {
        await _client
            .from('todo_tasks')
            .delete()
            .eq('id', todo.id!)
            .eq('user_id', _userId);
        _cache.removeTodoFromCache(todo.id!);
        _emitTodosFromCache();
        return;
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }

    await _cache.enqueue(SyncOperation(
      table: 'todo_tasks',
      action: 'delete',
      data: {},
      id: todo.id,
    ));
    _cache.removeTodoFromCache(todo.id!);
    _emitTodosFromCache();
    _schedulePendingSync();
  }

  /// Marks a todo as completed, creates a transaction, and schedules the next
  /// occurrence if recurrent. Returns the newly created TodoTask (next occurrence)
  /// if applicable, otherwise null.
  Future<TodoTask?> completeTodo(TodoTask todo,
      {double? adjustedAmount}) async {
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
        final txResponse = await _client
            .from('transactions')
            .insert(txData)
            .select(_transactionSelect)
            .single();
        newTransactionId = txResponse['id'] as String?;
        _cache.addTransactionToCache(Map<String, dynamic>.from(txResponse));
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
      }
    }
    if (newTransactionId == null) {
      newTransactionId = _generateUuid();
      final offlineTxData = {'id': newTransactionId, ...txData};
      await _cache.enqueue(SyncOperation(
        table: 'transactions',
        action: 'insert',
        data: offlineTxData,
      ));
      _cache.addTransactionToCache(
        _augmentRowForTable('transactions', offlineTxData),
      );
    }

    // 2. Mark todo as completed
    final completedData = {
      'is_completed': true,
      'completed_at': now.toIso8601String(),
      'transaction_id': newTransactionId,
    };
    if (_isOnline) {
      try {
        final response = await _client
            .from('todo_tasks')
            .update(completedData)
            .eq('id', todo.id!)
            .eq('user_id', _userId)
            .select(_todoSelect)
            .single();
        _cache.updateTodoInCache(Map<String, dynamic>.from(response));
      } catch (e) {
        debugPrint('SupabaseDataService: $e');
        await _cache.enqueue(SyncOperation(
          table: 'todo_tasks',
          action: 'update',
          data: completedData,
          id: todo.id,
        ));
        _cache.updateTodoInCache({
          ..._todoCacheData(todo),
          ...completedData,
        });
      }
    } else {
      await _cache.enqueue(SyncOperation(
        table: 'todo_tasks',
        action: 'update',
        data: completedData,
        id: todo.id,
      ));
      _cache.updateTodoInCache({
        ..._todoCacheData(todo),
        ...completedData,
      });
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
          final nextResponse = await _client
              .from('todo_tasks')
              .insert(nextData)
              .select(_todoSelect)
              .single();
          final nextRow = Map<String, dynamic>.from(nextResponse);
          _cache.addTodoToCache(nextRow);
          nextTodo = TodoTask.fromJson(nextRow);
        } catch (e) {
          final nextId = _generateUuid();
          final offlineNextData = {'id': nextId, ...nextData};
          await _cache.enqueue(SyncOperation(
            table: 'todo_tasks',
            action: 'insert',
            data: offlineNextData,
          ));
          _cache.addTodoToCache(
              _augmentRowForTable('todo_tasks', offlineNextData));
          nextTodo = TodoTask(
            id: nextId,
            userId: _userId,
            title: todo.title,
            amount: todo.amount,
            type: todo.type,
            categoryId: todo.categoryId,
            dueDate: nextDueDate,
            recurrence: todo.recurrence,
          );
        }
      } else {
        final nextId = _generateUuid();
        final offlineNextData = {'id': nextId, ...nextData};
        await _cache.enqueue(SyncOperation(
          table: 'todo_tasks',
          action: 'insert',
          data: offlineNextData,
        ));
        _cache
            .addTodoToCache(_augmentRowForTable('todo_tasks', offlineNextData));
        nextTodo = TodoTask(
          id: nextId,
          userId: _userId,
          title: todo.title,
          amount: todo.amount,
          type: todo.type,
          categoryId: todo.categoryId,
          dueDate: nextDueDate,
          recurrence: todo.recurrence,
        );
      }
    }

    _emitTodosFromCache();
    await _emitTransactionsFromCache(refreshBudgets: true);
    _schedulePendingSync();
    return nextTodo;
  }
}
