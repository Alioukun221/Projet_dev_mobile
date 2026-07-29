import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncOperation {
  final String table;
  final String action; // 'insert', 'update', 'delete'
  final Map<String, dynamic> data;
  final String? id; // record id for update/delete

  SyncOperation({
    required this.table,
    required this.action,
    required this.data,
    this.id,
  });

  Map<String, dynamic> toJson() => {
        'table': table,
        'action': action,
        'data': data,
        'id': id,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        table: json['table'] as String,
        action: json['action'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        id: json['id'] as String?,
      );
}

class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._();
  LocalCacheService._();

  late SharedPreferences _prefs;

  static const _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);
  static const _iosOptions =
      IOSOptions(accessibility: KeychainAccessibility.first_unlock);
  final _secureStorage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
  static const _secureQueueKey = 'spendwise_sync_queue';
  static const _lastActiveUserKey = 'last_active_user_id';

  bool _initialized = false;
  String? _activeUserId;
  List<SyncOperation> _inMemoryQueue = [];

  final _pendingOpsController = StreamController<int>.broadcast();
  static const _idempotencyHistoryMax = 1500;
  static const _idempotencyHistoryRetention = Duration(days: 7);

  Stream<int> get pendingOpsStream => _pendingOpsController.stream;
  int get pendingOpsCount => _inMemoryQueue.length;
  bool get hasPendingOps => _inMemoryQueue.isNotEmpty;

  String? get activeUserId => _activeUserId;

  Future<void> init({
    String? userId,
    bool restoreLastActiveUser = false,
  }) async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
    if (userId != null) {
      _activeUserId = userId;
      await _prefs.setString(_lastActiveUserKey, userId);
    } else if (restoreLastActiveUser) {
      _activeUserId = _prefs.getString(_lastActiveUserKey);
    }
    await _loadQueueFromSecureStorage();
  }

  Future<void> setActiveUser(String userId) async {
    await init(userId: userId);
    _pendingOpsController.add(_inMemoryQueue.length);
  }

  void detachActiveUser() {
    _activeUserId = null;
    _inMemoryQueue = [];
    _pendingOpsController.add(0);
  }

  Future<void> clearUserData(String? userId) async {
    if (!_initialized) {
      await init();
    }
    final id = userId ?? _activeUserId;
    if (id == null) return;

    const keys = [
      'cache_transactions',
      'cache_budgets',
      'cache_categories',
      'cache_todos',
      'pending_transactions',
      'captured_transaction_idempotency_keys',
      'notif_enabled',
      'notif_consent',
      'notif_mode',
      'notif_wave',
      'notif_om',
      'notif_deposit_cat',
      'notif_withdrawal_cat',
    ];
    for (final key in keys) {
      await _prefs.remove(_scopedKey(key, id));
    }
    await _secureStorage.delete(key: _secureQueueStorageKey(id));
    if (_prefs.getString(_lastActiveUserKey) == id) {
      await _prefs.remove(_lastActiveUserKey);
    }
    if (_activeUserId == id) {
      detachActiveUser();
    }
  }

  Future<void> _loadQueueFromSecureStorage() async {
    try {
      _inMemoryQueue = [];
      // Migrate legacy SharedPreferences sync_queue if present
      final legacy = _prefs.getString(_scopedKey('sync_queue'));
      if (legacy != null && legacy != '[]') {
        final legacyOps = (jsonDecode(legacy) as List)
            .map((e) =>
                SyncOperation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _inMemoryQueue.addAll(legacyOps);
        await _persistQueue();
        await _prefs.remove(_scopedKey('sync_queue'));
      } else {
        final json = await _secureStorage.read(key: _secureQueueStorageKey());
        if (json != null && json.isNotEmpty) {
          _inMemoryQueue = (jsonDecode(json) as List)
              .map((e) =>
                  SyncOperation.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('LocalCacheService: failed to load sync queue: $e');
      _inMemoryQueue = [];
    }
  }

  // ============ CACHE READ/WRITE ============

  List<Map<String, dynamic>> getCachedTransactions() =>
      _getList('cache_transactions');

  void cacheTransactions(List<dynamic> data) =>
      _setList('cache_transactions', data);

  void addTransactionToCache(Map<String, dynamic> data) {
    final list = getCachedTransactions();
    final idx = list.indexWhere((t) => t['id'] == data['id']);
    if (idx == -1) {
      list.insert(0, data);
    } else {
      list[idx] = _mergeMaps(list[idx], data);
    }
    cacheTransactions(_sortByDate(list, 'date', descending: true));
  }

  void updateTransactionInCache(Map<String, dynamic> data) {
    final list = getCachedTransactions();
    final idx = list.indexWhere((t) => t['id'] == data['id']);
    if (idx != -1) {
      list[idx] = _mergeMaps(list[idx], data);
    } else if (data['id'] != null) {
      list.insert(0, data);
    }
    cacheTransactions(_sortByDate(list, 'date', descending: true));
  }

  void removeTransactionFromCache(String id) {
    final list = getCachedTransactions();
    list.removeWhere((t) => t['id'] == id);
    cacheTransactions(list);
  }

  List<Map<String, dynamic>> getCachedBudgets() => _getList('cache_budgets');

  void cacheBudgets(List<dynamic> data) => _setList('cache_budgets', data);

  void addBudgetToCache(Map<String, dynamic> data) {
    final list = getCachedBudgets();
    final idx = list.indexWhere((b) => b['id'] == data['id']);
    if (idx == -1) {
      list.insert(0, data);
    } else {
      list[idx] = _mergeMaps(list[idx], data);
    }
    cacheBudgets(_sortByDate(list, 'start_date', descending: true));
  }

  void updateBudgetInCache(Map<String, dynamic> data) {
    final list = getCachedBudgets();
    final idx = list.indexWhere((b) => b['id'] == data['id']);
    if (idx != -1) {
      list[idx] = _mergeMaps(list[idx], data);
    } else if (data['id'] != null) {
      list.insert(0, data);
    }
    cacheBudgets(_sortByDate(list, 'start_date', descending: true));
  }

  void removeBudgetFromCache(String id) {
    final list = getCachedBudgets();
    list.removeWhere((b) => b['id'] == id);
    cacheBudgets(list);
  }

  List<Map<String, dynamic>> getCachedCategories() =>
      _getList('cache_categories');

  void cacheCategories(List<dynamic> data) =>
      _setList('cache_categories', data);

  void addCategoryToCache(Map<String, dynamic> data) {
    final list = getCachedCategories();
    final idx = list.indexWhere((c) => c['id'] == data['id']);
    if (idx == -1) {
      list.add(data);
    } else {
      list[idx] = _mergeMaps(list[idx], data);
    }
    cacheCategories(_sortByName(list));
  }

  void updateCategoryInCache(Map<String, dynamic> data) {
    final list = getCachedCategories();
    final idx = list.indexWhere((c) => c['id'] == data['id']);
    if (idx != -1) {
      list[idx] = _mergeMaps(list[idx], data);
    } else if (data['id'] != null) {
      list.add(data);
    }
    cacheCategories(_sortByName(list));
  }

  void removeCategoryFromCache(String id) {
    final list = getCachedCategories();
    list.removeWhere((c) => c['id'] == id);
    cacheCategories(list);
  }

  List<Map<String, dynamic>> getCachedTodos() => _getList('cache_todos');

  void cacheTodos(List<dynamic> data) => _setList('cache_todos', data);

  void addTodoToCache(Map<String, dynamic> data) {
    final list = getCachedTodos();
    final idx = list.indexWhere((t) => t['id'] == data['id']);
    if (idx == -1) {
      list.add(data);
    } else {
      list[idx] = _mergeMaps(list[idx], data);
    }
    cacheTodos(_sortByDate(list, 'due_date'));
  }

  void updateTodoInCache(Map<String, dynamic> data) {
    final list = getCachedTodos();
    final idx = list.indexWhere((t) => t['id'] == data['id']);
    if (idx != -1) {
      list[idx] = _mergeMaps(list[idx], data);
    } else if (data['id'] != null) {
      list.add(data);
    }
    cacheTodos(_sortByDate(list, 'due_date'));
  }

  void removeTodoFromCache(String id) {
    final list = getCachedTodos();
    list.removeWhere((t) => t['id'] == id);
    cacheTodos(list);
  }

  // ============ SYNC QUEUE ============

  Future<void> enqueue(SyncOperation op) async {
    _inMemoryQueue.add(op);
    await _persistQueue();
    _pendingOpsController.add(_inMemoryQueue.length);
  }

  List<SyncOperation> getPendingOps() => List.unmodifiable(_inMemoryQueue);

  Future<void> clearQueue() async {
    _inMemoryQueue.clear();
    await _secureStorage.delete(key: _secureQueueStorageKey());
    _pendingOpsController.add(0);
  }

  Future<void> _persistQueue() async {
    await _secureStorage.write(
      key: _secureQueueStorageKey(),
      value: jsonEncode(_inMemoryQueue.map((e) => e.toJson()).toList()),
    );
  }

  // ============ NOTIFICATION SETTINGS ============

  bool get isNotificationListeningEnabled =>
      _prefs.getBool(_scopedKey('notif_enabled')) ?? false;

  set isNotificationListeningEnabled(bool value) =>
      _prefs.setBool(_scopedKey('notif_enabled'), value);

  bool get hasNotifConsent =>
      _prefs.getBool(_scopedKey('notif_consent')) ?? false;

  set hasNotifConsent(bool value) =>
      _prefs.setBool(_scopedKey('notif_consent'), value);

  String get notificationMode =>
      _prefs.getString(_scopedKey('notif_mode')) ?? 'confirmation';

  set notificationMode(String value) =>
      _prefs.setString(_scopedKey('notif_mode'), value);

  bool get isWaveEnabled => _prefs.getBool(_scopedKey('notif_wave')) ?? true;

  set isWaveEnabled(bool value) =>
      _prefs.setBool(_scopedKey('notif_wave'), value);

  bool get isOrangeMoneyEnabled =>
      _prefs.getBool(_scopedKey('notif_om')) ?? true;

  set isOrangeMoneyEnabled(bool value) =>
      _prefs.setBool(_scopedKey('notif_om'), value);

  String? get defaultDepositCategoryId =>
      _prefs.getString(_scopedKey('notif_deposit_cat'));

  set defaultDepositCategoryId(String? value) {
    if (value == null) {
      _prefs.remove(_scopedKey('notif_deposit_cat'));
    } else {
      _prefs.setString(_scopedKey('notif_deposit_cat'), value);
    }
  }

  String? get defaultWithdrawalCategoryId =>
      _prefs.getString(_scopedKey('notif_withdrawal_cat'));

  set defaultWithdrawalCategoryId(String? value) {
    if (value == null) {
      _prefs.remove(_scopedKey('notif_withdrawal_cat'));
    } else {
      _prefs.setString(_scopedKey('notif_withdrawal_cat'), value);
    }
  }

  // ============ PENDING TRANSACTIONS (SMS Wave/Orange Money) ============

  List<Map<String, dynamic>> getPendingTransactions() =>
      _getList('pending_transactions');

  bool addPendingTransaction(Map<String, dynamic> tx) {
    final list = _getRawList('pending_transactions');
    final newKeys = _stringList(tx['idempotency_keys']);
    if (newKeys.isNotEmpty) {
      final existingKeys = _pendingTransactionIdempotencyKeys(list);
      if (newKeys.any(existingKeys.contains)) {
        return false;
      }
    }
    list.add(tx);
    _setRawList('pending_transactions', list);
    return true;
  }

  void removePendingTransaction(String id) {
    final list = _getRawList('pending_transactions');
    list.removeWhere((tx) => (tx as Map)['id'] == id);
    _setRawList('pending_transactions', list);
  }

  void clearPendingTransactions() =>
      _prefs.setString(_scopedKey('pending_transactions'), '[]');

  int get pendingTransactionCount => getPendingTransactions().length;

  bool hasCapturedTransactionIdempotencyKey(Iterable<String> keys) {
    final probe = keys.where((key) => key.isNotEmpty).toSet();
    if (probe.isEmpty) return false;

    _pruneCapturedTransactionIdempotencyKeys();
    final captured = _capturedTransactionIdempotencyKeySet();
    if (probe.any(captured.contains)) return true;

    final pending = _pendingTransactionIdempotencyKeys(
      _getRawList('pending_transactions'),
    );
    return probe.any(pending.contains);
  }

  void rememberCapturedTransactionIdempotencyKeys(Iterable<String> keys) {
    final cleanKeys = keys.where((key) => key.isNotEmpty).toSet();
    if (cleanKeys.isEmpty) return;

    final now = DateTime.now();
    final byKey = <String, DateTime>{};
    for (final item in _getRawList('captured_transaction_idempotency_keys')) {
      if (item is! Map) continue;
      final key = item['key']?.toString();
      final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
      if (key == null || key.isEmpty || createdAt == null) continue;
      byKey[key] = createdAt;
    }
    for (final key in cleanKeys) {
      byKey[key] = now;
    }
    _writeCapturedTransactionIdempotencyKeys(byKey);
  }

  void forgetCapturedTransactionIdempotencyKeys(Iterable<String> keys) {
    final removeKeys = keys.where((key) => key.isNotEmpty).toSet();
    if (removeKeys.isEmpty) return;

    final byKey = <String, DateTime>{};
    for (final item in _getRawList('captured_transaction_idempotency_keys')) {
      if (item is! Map) continue;
      final key = item['key']?.toString();
      final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
      if (key == null ||
          key.isEmpty ||
          createdAt == null ||
          removeKeys.contains(key)) {
        continue;
      }
      byKey[key] = createdAt;
    }
    _writeCapturedTransactionIdempotencyKeys(byKey);
  }

  // ============ HELPERS ============

  List<Map<String, dynamic>> _getList(String key) {
    return _getRawList(key)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<dynamic> _getRawList(String key) {
    try {
      final raw = _prefs.getString(_scopedKey(key));
      if (raw == null) return [];
      return jsonDecode(raw) as List;
    } catch (e) {
      debugPrint('LocalCacheService._getRawList($key): $e');
      return [];
    }
  }

  void _setList(String key, List<dynamic> data) {
    try {
      _prefs.setString(_scopedKey(key), jsonEncode(data));
    } catch (e) {
      debugPrint('LocalCacheService._setList($key): $e');
    }
  }

  void _setRawList(String key, List<dynamic> data) {
    try {
      _prefs.setString(_scopedKey(key), jsonEncode(data));
    } catch (e) {
      debugPrint('LocalCacheService._setRawList($key): $e');
    }
  }

  Set<String> _pendingTransactionIdempotencyKeys([List<dynamic>? pending]) {
    final keys = <String>{};
    for (final item in pending ?? _getRawList('pending_transactions')) {
      if (item is! Map) continue;
      keys.addAll(_stringList(item['idempotency_keys']));
    }
    return keys;
  }

  Set<String> _capturedTransactionIdempotencyKeySet() {
    final keys = <String>{};
    for (final item in _getRawList('captured_transaction_idempotency_keys')) {
      if (item is! Map) continue;
      final key = item['key']?.toString();
      if (key != null && key.isNotEmpty) keys.add(key);
    }
    return keys;
  }

  void _pruneCapturedTransactionIdempotencyKeys() {
    final cutoff = DateTime.now().subtract(_idempotencyHistoryRetention);
    final byKey = <String, DateTime>{};
    var changed = false;

    for (final item in _getRawList('captured_transaction_idempotency_keys')) {
      if (item is! Map) {
        changed = true;
        continue;
      }
      final key = item['key']?.toString();
      final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
      if (key == null || key.isEmpty || createdAt == null) {
        changed = true;
        continue;
      }
      if (createdAt.isBefore(cutoff)) {
        changed = true;
        continue;
      }
      byKey[key] = createdAt;
    }

    if (changed) _writeCapturedTransactionIdempotencyKeys(byKey);
  }

  void _writeCapturedTransactionIdempotencyKeys(Map<String, DateTime> byKey) {
    final entries = byKey.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final kept = entries.take(_idempotencyHistoryMax).map((entry) {
      return {
        'key': entry.key,
        'created_at': entry.value.toIso8601String(),
      };
    }).toList();
    _setRawList('captured_transaction_idempotency_keys', kept);
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((key) => key.toString())
          .where((key) => key.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }

  String _scopedKey(String key, [String? userId]) {
    final id = userId ?? _activeUserId;
    return id == null ? key : '${key}_$id';
  }

  String _secureQueueStorageKey([String? userId]) {
    final id = userId ?? _activeUserId;
    return id == null ? _secureQueueKey : '${_secureQueueKey}_$id';
  }

  Map<String, dynamic> _mergeMaps(
    Map<String, dynamic> current,
    Map<String, dynamic> update,
  ) {
    return {...current, ...update};
  }

  List<Map<String, dynamic>> _sortByDate(
    List<Map<String, dynamic>> list,
    String key, {
    bool descending = false,
  }) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      final aDate = DateTime.tryParse(a[key]?.toString() ?? '');
      final bDate = DateTime.tryParse(b[key]?.toString() ?? '');
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return descending ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });
    return sorted;
  }

  List<Map<String, dynamic>> _sortByName(List<Map<String, dynamic>> list) {
    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) =>
        (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
    return sorted;
  }
}
