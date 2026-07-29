import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:spendwise/models/parsed_transaction.dart';
import 'package:spendwise/models/pending_transaction.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/local_cache_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/services/transaction_parser.dart';
import 'package:spendwise/utils/transaction_idempotency.dart';

class NotificationTransactionService {
  static final NotificationTransactionService _instance =
      NotificationTransactionService._internal();
  factory NotificationTransactionService() => _instance;
  NotificationTransactionService._internal();

  final _cache = LocalCacheService.instance;
  StreamSubscription? _notificationSub;
  bool _initialized = false;

  // Deduplication: LinkedHashSet pour conserver l'ordre d'insertion
  final LinkedHashSet<String> _recentHashes = LinkedHashSet();
  static const int _maxHashHistory = 200;

  bool _isApproving = false;

  // Pending count stream for badge
  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  int get pendingCount => _cache.pendingTransactionCount;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Emit initial count
    _pendingCountController.add(_cache.pendingTransactionCount);

    // Start listening if enabled and permission granted
    if (_cache.isNotificationListeningEnabled) {
      final hasPermission =
          await NotificationListenerService.isPermissionGranted();
      if (hasPermission) {
        startListening();
      }
    }
  }

  void startListening() {
    _notificationSub?.cancel();
    _notificationSub = NotificationListenerService.notificationsStream
        .listen(_onNotificationReceived);
  }

  void stopListening() {
    _notificationSub?.cancel();
    _notificationSub = null;
  }

  void _onNotificationReceived(ServiceNotificationEvent event) {
    if (!_cache.hasNotifConsent || !_cache.isNotificationListeningEnabled) {
      return;
    }

    final packageName = event.packageName ?? '';
    final title = event.title ?? '';
    final content = event.content ?? '';

    // Filter: only Wave and Orange Money
    if (packageName != TransactionParser.wavePackage &&
        packageName != TransactionParser.orangeMoneyPackage) {
      return;
    }

    // Check per-service toggle
    if (packageName == TransactionParser.wavePackage && !_cache.isWaveEnabled) {
      return;
    }
    if (packageName == TransactionParser.orangeMoneyPackage &&
        !_cache.isOrangeMoneyEnabled) {
      return;
    }

    // Deduplication
    final hash = _computeHash(packageName, title, content);
    if (_recentHashes.contains(hash)) return;
    _recentHashes.add(hash);
    if (_recentHashes.length > _maxHashHistory) {
      _recentHashes.remove(_recentHashes.first);
    }

    // Parse
    final parsed = TransactionParser.parse(
      packageName: packageName,
      title: title,
      content: content,
    );
    if (parsed == null) return;

    final idempotencyKeys = TransactionIdempotency.forParsed(parsed);
    if (_cache.hasCapturedTransactionIdempotencyKey(
      idempotencyKeys.duplicateProbeKeys,
    )) {
      return;
    }

    // Route based on mode
    if (_cache.notificationMode == 'auto') {
      _autoCreateTransaction(parsed, idempotencyKeys);
    } else {
      _queueForConfirmation(parsed, idempotencyKeys);
    }
  }

  Future<void> _autoCreateTransaction(
    ParsedTransaction parsed,
    TransactionIdempotencyKeys idempotencyKeys,
  ) async {
    _cache.rememberCapturedTransactionIdempotencyKeys(
      idempotencyKeys.storeKeys,
    );
    try {
      final categoryId = await _resolveCategory(parsed.type);
      final transaction = Transaction(
        type: parsed.type,
        amount: parsed.amount,
        description: parsed.description,
        date: parsed.date,
        categoryId: categoryId,
      );
      await SupabaseDataService().addTransaction(transaction);
    } catch (e) {
      _cache.forgetCapturedTransactionIdempotencyKeys(
        idempotencyKeys.storeKeys,
      );
      debugPrint('NotificationTransactionService._autoCreateTransaction: $e');
    }
  }

  void _queueForConfirmation(
    ParsedTransaction parsed,
    TransactionIdempotencyKeys idempotencyKeys,
  ) {
    final pending = PendingTransaction.fromParsed(
      parsed,
      idempotencyKeys: idempotencyKeys.storeKeys,
    );
    final added = _cache.addPendingTransaction(pending.toJson());
    if (!added) return;
    _cache.rememberCapturedTransactionIdempotencyKeys(
      idempotencyKeys.storeKeys,
    );
    _pendingCountController.add(_cache.pendingTransactionCount);
  }

  Future<bool> approvePending(String id) async {
    final items = _cache.getPendingTransactions();
    final json = items.firstWhere(
      (tx) => tx['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    if (json.isEmpty) return false;

    // Optimistic: remove from cache immediately
    _cache.removePendingTransaction(id);
    _pendingCountController.add(_cache.pendingTransactionCount);

    try {
      final pending = PendingTransaction.fromJson(json);
      final categoryId = await _resolveCategory(pending.type);
      await SupabaseDataService().addTransaction(Transaction(
        type: pending.type,
        amount: pending.amount,
        description: pending.description,
        date: pending.date,
        categoryId: categoryId,
      ));
    } catch (e) {
      debugPrint('NotificationTransactionService.approvePending: $e');
      // Re-add to queue on failure
      _cache.addPendingTransaction(json);
      _pendingCountController.add(_cache.pendingTransactionCount);
      return false;
    }
    return true;
  }

  Future<int> approveAll() async {
    if (_isApproving) return 0;
    _isApproving = true;

    try {
      final items =
          List<Map<String, dynamic>>.from(_cache.getPendingTransactions());
      if (items.isEmpty) return 0;

      // Optimistic: clear all immediately so UI updates at once
      for (final json in items) {
        _cache.removePendingTransaction(PendingTransaction.fromJson(json).id);
      }
      _pendingCountController.add(0);

      // Resolve shared categories once
      final depositCatId = await _resolveCategory('deposit');
      final withdrawalCatId = await _resolveCategory('withdrawal');

      // Process all in parallel
      var failedCount = 0;
      await Future.wait(items.map((json) async {
        try {
          final pending = PendingTransaction.fromJson(json);
          final categoryId =
              pending.type == 'deposit' ? depositCatId : withdrawalCatId;
          await SupabaseDataService().addTransaction(Transaction(
            type: pending.type,
            amount: pending.amount,
            description: pending.description,
            date: pending.date,
            categoryId: categoryId,
          ));
        } catch (e) {
          debugPrint('NotificationTransactionService.approveAll item: $e');
          // Re-add failed items
          _cache.addPendingTransaction(json);
          failedCount++;
        }
      }));

      _pendingCountController.add(_cache.pendingTransactionCount);
      return failedCount;
    } finally {
      _isApproving = false;
    }
  }

  void rejectPending(String id) {
    _cache.removePendingTransaction(id);
    _pendingCountController.add(_cache.pendingTransactionCount);
  }

  void notifyPendingUpdated() {
    _pendingCountController.add(_cache.pendingTransactionCount);
  }

  List<PendingTransaction> getPendingTransactions() {
    return _cache
        .getPendingTransactions()
        .map((json) => PendingTransaction.fromJson(json))
        .toList();
  }

  Future<String?> _resolveCategory(String type) async {
    // Check user-configured default category
    if (type == 'deposit') {
      final id = _cache.defaultDepositCategoryId;
      if (id != null) return id;
    } else {
      final id = _cache.defaultWithdrawalCategoryId;
      if (id != null) return id;
    }

    // Fallback: try "Transfert" category
    try {
      final transferId =
          await SupabaseDataService().getCategoryIdByName('Transfert');
      if (transferId != null) return transferId;

      final categories = await SupabaseDataService().getCategories();
      if (categories.isNotEmpty) return categories.first.id;
    } catch (e) {
      debugPrint('NotificationTransactionService._resolveCategory: $e');
    }

    return null;
  }

  String _computeHash(String packageName, String title, String content) {
    // Second-precision key avoids false positives on identical legitimate transactions
    final dateKey = DateTime.now().toIso8601String().substring(0, 19);
    final input = '$packageName|$title|$content|$dateKey';
    return sha256.convert(utf8.encode(input)).toString();
  }

  void dispose() {
    stopListening();
    _pendingCountController.close();
  }
}
