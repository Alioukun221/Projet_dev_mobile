import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ CACHE READ/WRITE ============

  List<Map<String, dynamic>> getCachedTransactions() =>
      _getList('cache_transactions');

  void cacheTransactions(List<dynamic> data) =>
      _setList('cache_transactions', data);

  List<Map<String, dynamic>> getCachedBudgets() => _getList('cache_budgets');

  void cacheBudgets(List<dynamic> data) => _setList('cache_budgets', data);

  List<Map<String, dynamic>> getCachedCategories() =>
      _getList('cache_categories');

  void cacheCategories(List<dynamic> data) =>
      _setList('cache_categories', data);

  List<Map<String, dynamic>> getCachedTodos() => _getList('cache_todos');

  void cacheTodos(List<dynamic> data) => _setList('cache_todos', data);

  // ============ SYNC QUEUE ============

  void enqueue(SyncOperation op) {
    final list = _getRawList('sync_queue');
    list.add(op.toJson());
    _setRawList('sync_queue', list);
  }

  List<SyncOperation> getPendingOps() {
    return _getRawList('sync_queue')
        .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void clearQueue() => _prefs.setString('sync_queue', '[]');

  bool get hasPendingOps => _getRawList('sync_queue').isNotEmpty;

  // ============ NOTIFICATION SETTINGS ============

  bool get isNotificationListeningEnabled =>
      _prefs.getBool('notif_enabled') ?? false;

  set isNotificationListeningEnabled(bool value) =>
      _prefs.setBool('notif_enabled', value);

  String get notificationMode =>
      _prefs.getString('notif_mode') ?? 'confirmation';

  set notificationMode(String value) => _prefs.setString('notif_mode', value);

  bool get isWaveEnabled => _prefs.getBool('notif_wave') ?? true;

  set isWaveEnabled(bool value) => _prefs.setBool('notif_wave', value);

  bool get isOrangeMoneyEnabled => _prefs.getBool('notif_om') ?? true;

  set isOrangeMoneyEnabled(bool value) => _prefs.setBool('notif_om', value);

  String? get defaultDepositCategoryId =>
      _prefs.getString('notif_deposit_cat');

  set defaultDepositCategoryId(String? value) {
    if (value == null) {
      _prefs.remove('notif_deposit_cat');
    } else {
      _prefs.setString('notif_deposit_cat', value);
    }
  }

  String? get defaultWithdrawalCategoryId =>
      _prefs.getString('notif_withdrawal_cat');

  set defaultWithdrawalCategoryId(String? value) {
    if (value == null) {
      _prefs.remove('notif_withdrawal_cat');
    } else {
      _prefs.setString('notif_withdrawal_cat', value);
    }
  }

  // ============ PENDING TRANSACTIONS (SMS Wave/Orange Money) ============

  List<Map<String, dynamic>> getPendingTransactions() =>
      _getList('pending_transactions');

  void addPendingTransaction(Map<String, dynamic> tx) {
    final list = _getRawList('pending_transactions');
    list.add(tx);
    _setRawList('pending_transactions', list);
  }

  void removePendingTransaction(String id) {
    final list = _getRawList('pending_transactions');
    list.removeWhere((tx) => (tx as Map)['id'] == id);
    _setRawList('pending_transactions', list);
  }

  void clearPendingTransactions() =>
      _prefs.setString('pending_transactions', '[]');

  int get pendingTransactionCount => getPendingTransactions().length;

  // ============ HELPERS ============

  List<Map<String, dynamic>> _getList(String key) {
    return _getRawList(key)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<dynamic> _getRawList(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return [];
      return jsonDecode(raw) as List;
    } catch (e) {
      debugPrint('LocalCacheService._getRawList($key): $e');
      return [];
    }
  }

  void _setList(String key, List<dynamic> data) {
    try {
      _prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('LocalCacheService._setList($key): $e');
    }
  }

  void _setRawList(String key, List<dynamic> data) {
    try {
      _prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('LocalCacheService._setRawList($key): $e');
    }
  }
}
