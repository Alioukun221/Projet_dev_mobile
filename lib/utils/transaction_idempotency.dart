import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:spendwise/models/parsed_transaction.dart';

class TransactionIdempotencyKeys {
  final List<String> storeKeys;
  final List<String> duplicateProbeKeys;

  const TransactionIdempotencyKeys({
    required this.storeKeys,
    required this.duplicateProbeKeys,
  });
}

class TransactionIdempotency {
  static const _bucketSize = Duration(minutes: 10);

  static TransactionIdempotencyKeys forParsed(ParsedTransaction parsed) {
    final store = <String>{};
    final probes = <String>{};
    final raw = _normalizedRaw(parsed);

    final exactKey = 'exact:${parsed.source}:${_hash(raw)}';
    store.add(exactKey);
    probes.add(exactKey);

    final reference = _extractReference(raw);
    if (reference != null) {
      final referenceKey = 'ref:${parsed.source}:$reference';
      store.add(referenceKey);
      probes.add(referenceKey);
    }

    if (_looksLikeTransfer(raw)) {
      final amount = _amountKey(parsed.amount);
      final ownType = parsed.type;
      final otherType = ownType == 'deposit' ? 'withdrawal' : 'deposit';
      final bucket = _bucketIndex(parsed.date);
      for (var offset = -1; offset <= 1; offset++) {
        final currentBucket = bucket + offset;
        store.add('pair:${parsed.source}:$ownType:$amount:$currentBucket');
        probes.add('pair:${parsed.source}:$otherType:$amount:$currentBucket');
      }
    }

    return TransactionIdempotencyKeys(
      storeKeys: store.toList(growable: false),
      duplicateProbeKeys: probes.toList(growable: false),
    );
  }

  static String _normalizedRaw(ParsedTransaction parsed) {
    return '${parsed.rawTitle} ${parsed.rawContent}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikeTransfer(String raw) {
    final hasTransferSignal = RegExp(
      r'\b(transfert|transfer|envoi|envoy[eé]|sent|re[cç]u|received)\b',
      caseSensitive: false,
    ).hasMatch(raw);
    final hasNonTransferSignal = RegExp(
      r'\b(paiement|payment|pay[eé]|achat|retrait|retir[eé]|withdrawal|d[eé]p[oô]t|deposit|rechargement|distributeur)\b',
      caseSensitive: false,
    ).hasMatch(raw);
    return hasTransferSignal && !hasNonTransferSignal;
  }

  static String? _extractReference(String raw) {
    final patterns = [
      RegExp(
        r'\b(?:ref(?:erence)?|r[eé]f(?:[eé]rence)?|id|code|txn|trx)[:\s#-]*([a-z0-9]{6,})\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\btransaction[:\s#-]*([a-z0-9]{6,})\b',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match != null) {
        return match.group(1)!.toLowerCase();
      }
    }
    return null;
  }

  static int _amountKey(double amount) => (amount * 100).round();

  static int _bucketIndex(DateTime date) {
    return date.toUtc().millisecondsSinceEpoch ~/ _bucketSize.inMilliseconds;
  }

  static String _hash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
