import 'package:hive_flutter/hive_flutter.dart';

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

  late Box _transactionsBox;
  late Box _budgetsBox;
  late Box _categoriesBox;
  late Box _syncQueueBox;
  late Box _notificationSettingsBox;
  late Box _pendingTransactionsBox;

  Future<void> init() async {
    _transactionsBox = await Hive.openBox('cache_transactions');
    _budgetsBox = await Hive.openBox('cache_budgets');
    _categoriesBox = await Hive.openBox('cache_categories');
    _syncQueueBox = await Hive.openBox('sync_queue');
    _notificationSettingsBox = await Hive.openBox('notification_settings');
    _pendingTransactionsBox = await Hive.openBox('pending_transactions');
  }

  // ============ CACHE READ/WRITE ============

  List<Map<String, dynamic>> getCachedTransactions() {
    final raw = _transactionsBox.get('data');
    if (raw == null) return [];
    return (raw as List).map((e) => _deepCastMap(e)).toList();
  }

  void cacheTransactions(List<dynamic> data) {
    _transactionsBox.put('data', data);
  }

  List<Map<String, dynamic>> getCachedBudgets() {
    final raw = _budgetsBox.get('data');
    if (raw == null) return [];
    return (raw as List).map((e) => _deepCastMap(e)).toList();
  }

  void cacheBudgets(List<dynamic> data) {
    _budgetsBox.put('data', data);
  }

  List<Map<String, dynamic>> getCachedCategories() {
    final raw = _categoriesBox.get('data');
    if (raw == null) return [];
    return (raw as List).map((e) => _deepCastMap(e)).toList();
  }

  void cacheCategories(List<dynamic> data) {
    _categoriesBox.put('data', data);
  }

  // ============ SYNC QUEUE ============

  void enqueue(SyncOperation op) {
    final list = _getRawQueue();
    list.add(op.toJson());
    _syncQueueBox.put('ops', list);
  }

  List<SyncOperation> getPendingOps() {
    return _getRawQueue().map((e) => SyncOperation.fromJson(_deepCastMap(e))).toList();
  }

  void clearQueue() {
    _syncQueueBox.put('ops', []);
  }

  bool get hasPendingOps => _getRawQueue().isNotEmpty;

  List<dynamic> _getRawQueue() {
    final raw = _syncQueueBox.get('ops');
    if (raw == null) return [];
    return List.from(raw);
  }

  // ============ NOTIFICATION SETTINGS ============

  bool get isNotificationListeningEnabled =>
      _notificationSettingsBox.get('enabled', defaultValue: false) as bool;

  set isNotificationListeningEnabled(bool value) =>
      _notificationSettingsBox.put('enabled', value);

  String get notificationMode =>
      _notificationSettingsBox.get('mode', defaultValue: 'confirmation') as String;

  set notificationMode(String value) =>
      _notificationSettingsBox.put('mode', value);

  bool get isWaveEnabled =>
      _notificationSettingsBox.get('wave_enabled', defaultValue: true) as bool;

  set isWaveEnabled(bool value) =>
      _notificationSettingsBox.put('wave_enabled', value);

  bool get isOrangeMoneyEnabled =>
      _notificationSettingsBox.get('om_enabled', defaultValue: true) as bool;

  set isOrangeMoneyEnabled(bool value) =>
      _notificationSettingsBox.put('om_enabled', value);

  String? get defaultDepositCategoryId =>
      _notificationSettingsBox.get('deposit_category_id') as String?;

  set defaultDepositCategoryId(String? value) =>
      _notificationSettingsBox.put('deposit_category_id', value);

  String? get defaultWithdrawalCategoryId =>
      _notificationSettingsBox.get('withdrawal_category_id') as String?;

  set defaultWithdrawalCategoryId(String? value) =>
      _notificationSettingsBox.put('withdrawal_category_id', value);

  // ============ PENDING TRANSACTIONS ============

  List<Map<String, dynamic>> getPendingTransactions() {
    final raw = _pendingTransactionsBox.get('items');
    if (raw == null) return [];
    return (raw as List).map((e) => _deepCastMap(e)).toList();
  }

  void addPendingTransaction(Map<String, dynamic> tx) {
    final list = getPendingTransactions();
    list.add(tx);
    _pendingTransactionsBox.put('items', list);
  }

  void removePendingTransaction(String id) {
    final list = getPendingTransactions();
    list.removeWhere((tx) => tx['id'] == id);
    _pendingTransactionsBox.put('items', list);
  }

  void clearPendingTransactions() {
    _pendingTransactionsBox.put('items', []);
  }

  int get pendingTransactionCount => getPendingTransactions().length;

  // Recursively cast Hive's internal maps to Map<String, dynamic>
  Map<String, dynamic> _deepCastMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) {
        if (v is Map) return MapEntry(k.toString(), _deepCastMap(v));
        if (v is List) return MapEntry(k.toString(), v.map((e) => e is Map ? _deepCastMap(e) : e).toList());
        return MapEntry(k.toString(), v);
      });
    }
    return {};
  }
}
