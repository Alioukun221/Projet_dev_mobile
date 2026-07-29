import 'dart:ui';
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:spendwise/models/parsed_transaction.dart';
import 'package:spendwise/models/pending_transaction.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/local_cache_service.dart';
import 'package:spendwise/services/notification_transaction_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/services/transaction_parser.dart';
import 'package:spendwise/utils/transaction_idempotency.dart';

// Top-level handler required by telephony for background SMS
@pragma('vm:entry-point')
Future<void> _backgroundSmsHandler(SmsMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await LocalCacheService.instance.init(restoreLastActiveUser: true);

  final body = message.body ?? '';
  if (!body.contains('OFMS')) return;
  final cache = LocalCacheService.instance;
  if (cache.activeUserId == null) return;
  if (!cache.hasNotifConsent || !cache.isNotificationListeningEnabled) return;
  if (!cache.isOrangeMoneyEnabled) return;
  final parsed = TransactionParser.parseSms(body);
  if (parsed == null) return;
  final idempotencyKeys = TransactionIdempotency.forParsed(parsed);
  if (cache.hasCapturedTransactionIdempotencyKey(
    idempotencyKeys.duplicateProbeKeys,
  )) {
    return;
  }
  final pending = PendingTransaction.fromParsed(
    parsed,
    idempotencyKeys: idempotencyKeys.storeKeys,
  );
  final added = cache.addPendingTransaction(pending.toJson());
  if (added) {
    cache.rememberCapturedTransactionIdempotencyKeys(
      idempotencyKeys.storeKeys,
    );
  }
}

class SmsTransactionService {
  static final SmsTransactionService _instance =
      SmsTransactionService._internal();
  factory SmsTransactionService() => _instance;
  SmsTransactionService._internal();

  final _cache = LocalCacheService.instance;
  final _telephony = Telephony.instance;
  bool _initialized = false;
  bool _listening = false;

  final LinkedHashSet<String> _recentHashes = LinkedHashSet();
  static const int _maxHashHistory = 200;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (_cache.hasNotifConsent &&
        _cache.isNotificationListeningEnabled &&
        _cache.isOrangeMoneyEnabled) {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (_listening) return;
    _listening = true;
    _telephony.listenIncomingSms(
      onNewMessage: _onSmsReceived,
      onBackgroundMessage: _backgroundSmsHandler,
      listenInBackground: true,
    );
  }

  void stopListening() {
    _listening = false;
    // telephony does not expose a cancel — toggling via _listening flag
  }

  void _onSmsReceived(SmsMessage message) {
    final body = message.body ?? '';
    if (!body.contains('OFMS')) return;
    if (!_cache.hasNotifConsent || !_cache.isNotificationListeningEnabled) {
      return;
    }
    if (!_cache.isOrangeMoneyEnabled) return;

    // Deduplication
    final hash = _computeHash(body);
    if (_recentHashes.contains(hash)) return;
    _recentHashes.add(hash);
    if (_recentHashes.length > _maxHashHistory) {
      _recentHashes.remove(_recentHashes.first);
    }

    final parsed = TransactionParser.parseSms(body);
    if (parsed == null) return;

    final idempotencyKeys = TransactionIdempotency.forParsed(parsed);
    if (_cache.hasCapturedTransactionIdempotencyKey(
      idempotencyKeys.duplicateProbeKeys,
    )) {
      return;
    }

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
      debugPrint('SmsTransactionService._autoCreateTransaction: $e');
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
    NotificationTransactionService().notifyPendingUpdated();
  }

  Future<String?> _resolveCategory(String type) async {
    if (type == 'deposit') {
      final id = _cache.defaultDepositCategoryId;
      if (id != null) return id;
    } else {
      final id = _cache.defaultWithdrawalCategoryId;
      if (id != null) return id;
    }
    try {
      final transferId =
          await SupabaseDataService().getCategoryIdByName('Transfert');
      if (transferId != null) return transferId;
      final categories = await SupabaseDataService().getCategories();
      if (categories.isNotEmpty) return categories.first.id;
    } catch (e) {
      debugPrint('SmsTransactionService._resolveCategory: $e');
    }
    return null;
  }

  String _computeHash(String body) {
    final dateKey = DateTime.now().toIso8601String().substring(0, 19);
    final input = 'sms|$body|$dateKey';
    return sha256.convert(utf8.encode(input)).toString();
  }

  void dispose() {
    stopListening();
  }
}
