import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:spendwise/models/parsed_transaction.dart';
import 'package:spendwise/models/pending_transaction.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/local_cache_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/services/transaction_parser.dart';

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
    _notificationSub =
        NotificationListenerService.notificationsStream.listen(_onNotificationReceived);
  }

  void stopListening() {
    _notificationSub?.cancel();
    _notificationSub = null;
  }

  void _onNotificationReceived(ServiceNotificationEvent event) {
    final packageName = event.packageName ?? '';
    final title = event.title ?? '';
    final content = event.content ?? '';

    // Filter: only Wave and Orange Money
    if (packageName != TransactionParser.wavePackage &&
        packageName != TransactionParser.orangeMoneyPackage) {
      return;
    }

    // Check per-service toggle
    if (packageName == TransactionParser.wavePackage &&
        !_cache.isWaveEnabled) {
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

    // Route based on mode
    if (_cache.notificationMode == 'auto') {
      _autoCreateTransaction(parsed);
    } else {
      _queueForConfirmation(parsed);
    }
  }

  Future<void> _autoCreateTransaction(ParsedTransaction parsed) async {
    final categoryId = await _resolveCategory(parsed.type);
    final transaction = Transaction(
      type: parsed.type,
      amount: parsed.amount,
      description: parsed.description,
      date: parsed.date,
      categoryId: categoryId,
    );
    await SupabaseDataService().addTransaction(transaction);
  }

  void _queueForConfirmation(ParsedTransaction parsed) {
    final pending = PendingTransaction.fromParsed(parsed);
    _cache.addPendingTransaction(pending.toJson());
    _pendingCountController.add(_cache.pendingTransactionCount);
  }

  Future<void> approvePending(String id) async {
    if (_isApproving) return;

    final items = _cache.getPendingTransactions();
    final json = items.firstWhere(
      (tx) => tx['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    if (json.isEmpty) return;

    final pending = PendingTransaction.fromJson(json);
    final categoryId = await _resolveCategory(pending.type);
    final transaction = Transaction(
      type: pending.type,
      amount: pending.amount,
      description: pending.description,
      date: pending.date,
      categoryId: categoryId,
    );

    // Supprimer du cache seulement si Supabase réussit
    await SupabaseDataService().addTransaction(transaction);
    _cache.removePendingTransaction(id);
    _pendingCountController.add(_cache.pendingTransactionCount);
  }

  Future<void> approveAll() async {
    if (_isApproving) return;
    _isApproving = true;

    try {
      final items = List<Map<String, dynamic>>.from(_cache.getPendingTransactions());
      final List<String> approved = [];

      for (final json in items) {
        try {
          final pending = PendingTransaction.fromJson(json);
          final categoryId = await _resolveCategory(pending.type);
          final transaction = Transaction(
            type: pending.type,
            amount: pending.amount,
            description: pending.description,
            date: pending.date,
            categoryId: categoryId,
          );
          await SupabaseDataService().addTransaction(transaction);
          approved.add(pending.id);
        } catch (e) {
          debugPrint('NotificationTransactionService.approveAll: $e');
        }
      }

      // Supprimer uniquement celles qui ont réussi
      for (final id in approved) {
        _cache.removePendingTransaction(id);
      }
      _pendingCountController.add(_cache.pendingTransactionCount);
    } finally {
      _isApproving = false;
    }
  }

  void rejectPending(String id) {
    _cache.removePendingTransaction(id);
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
    final transferId =
        await SupabaseDataService().getCategoryIdByName('Transfert');
    if (transferId != null) return transferId;

    // Last fallback: first available category
    final categories = await SupabaseDataService().getCategories();
    if (categories.isNotEmpty) return categories.first.id;

    return null;
  }

  String _computeHash(String packageName, String title, String content) {
    // Précision seconde : évite les faux positifs sur transactions légitimes identiques
    final dateKey = DateTime.now().toIso8601String().substring(0, 19);
    final input = '$packageName|$title|$content|$dateKey';
    return input.hashCode.toRadixString(36);
  }

  void dispose() {
    stopListening();
    _pendingCountController.close();
  }
}
