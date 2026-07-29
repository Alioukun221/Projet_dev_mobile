import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/parsed_transaction.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/finance_ai_service.dart';
import 'package:spendwise/services/transaction_parser.dart';
import 'package:spendwise/utils/transaction_idempotency.dart';

void main() {
  test('Transaction parses Supabase rows and serializes writable fields', () {
    final transaction = Transaction.fromJson({
      'id': 'tx-1',
      'user_id': 'user-1',
      'category_id': 'cat-1',
      'categories': {'name': 'Transport'},
      'type': 'withdrawal',
      'amount': 2500,
      'description': 'Taxi',
      'date': '2026-07-07T12:00:00.000Z',
      'created_at': '2026-07-07T12:01:00.000Z',
      'updated_at': '2026-07-07T12:02:00.000Z',
    });

    expect(transaction.id, 'tx-1');
    expect(transaction.userId, 'user-1');
    expect(transaction.categoryName, 'Transport');
    expect(transaction.isDeposit, isFalse);
    expect(transaction.amount, 2500);

    expect(transaction.toJson(), {
      'category_id': 'cat-1',
      'type': 'withdrawal',
      'amount': 2500.0,
      'description': 'Taxi',
      'date': '2026-07-07T12:00:00.000Z',
    });
  });

  group('TransactionParser', () {
    test('parses Wave received notifications as deposits', () {
      final parsed = TransactionParser.parse(
        packageName: TransactionParser.wavePackage,
        title: 'Wave',
        content: 'Vous avez recu 5 000 FCFA de Ali.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.type, 'deposit');
      expect(parsed.amount, 5000);
      expect(parsed.source, 'wave');
    });

    test('parses certified Orange Money SMS deposits and withdrawals', () {
      final received = TransactionParser.parseSms(
        'Vous avez recu un transfert de 10000.00FCFA de Awa. Merci.OFMS',
      );
      final sent = TransactionParser.parseSms(
        'Votre transfert de 1200.00Fcfa vers Moussa a reussi. Merci.OFMS',
      );

      expect(received, isNotNull);
      expect(received!.type, 'deposit');
      expect(received.amount, 10000);
      expect(received.source, 'orange_money');

      expect(sent, isNotNull);
      expect(sent!.type, 'withdrawal');
      expect(sent.amount, 1200);
      expect(sent.source, 'orange_money');
    });

    test('rejects Orange Money-like SMS without OFMS marker', () {
      final parsed = TransactionParser.parseSms(
        'Vous avez recu un transfert de 10000.00FCFA de Awa.',
      );

      expect(parsed, isNull);
    });
  });

  group('TransactionIdempotency', () {
    test('matches opposite sides of the same transfer window', () {
      final date = DateTime.utc(2026, 7, 7, 12, 5);
      final withdrawal = _parsed(
        type: 'withdrawal',
        amount: 1200,
        rawContent: 'Votre transfert de 1200.00Fcfa vers 221771234567.',
        date: date,
      );
      final deposit = _parsed(
        type: 'deposit',
        amount: 1200,
        rawContent:
            'Vous avez recu un transfert de 1200.00FCFA de 221771234567.',
        date: date.add(const Duration(minutes: 3)),
      );

      final stored = TransactionIdempotency.forParsed(withdrawal).storeKeys;
      final probes =
          TransactionIdempotency.forParsed(deposit).duplicateProbeKeys;

      expect(stored.toSet().intersection(probes.toSet()), isNotEmpty);
    });

    test('does not collapse two same-direction transfers by amount only', () {
      final date = DateTime.utc(2026, 7, 7, 12, 5);
      final first = _parsed(
        type: 'deposit',
        amount: 5000,
        rawContent: 'Vous avez recu 5000 FCFA de Ali.',
        date: date,
      );
      final second = _parsed(
        type: 'deposit',
        amount: 5000,
        rawContent: 'Vous avez recu 5000 FCFA de Awa.',
        date: date.add(const Duration(minutes: 2)),
      );

      final stored = TransactionIdempotency.forParsed(first).storeKeys;
      final probes =
          TransactionIdempotency.forParsed(second).duplicateProbeKeys;

      expect(stored.toSet().intersection(probes.toSet()), isEmpty);
    });

    test('does not pair non-transfer cash movements', () {
      final date = DateTime.utc(2026, 7, 7, 12, 5);
      final cashWithdrawal = _parsed(
        type: 'withdrawal',
        amount: 7000,
        rawContent: 'Vous avez retire 7000.00FCFA par le distributeur.',
        date: date,
      );
      final deposit = _parsed(
        type: 'deposit',
        amount: 7000,
        rawContent: 'Depot de 7000 FCFA confirme.',
        date: date.add(const Duration(minutes: 2)),
      );

      final stored = TransactionIdempotency.forParsed(cashWithdrawal).storeKeys;
      final probes =
          TransactionIdempotency.forParsed(deposit).duplicateProbeKeys;

      expect(stored.toSet().intersection(probes.toSet()), isEmpty);
    });
  });

  test('FinanceAiService ignores Groq reasoning output blocks', () {
    final answer = FinanceAiService.extractAssistantAnswer({
      'output': [
        {
          'type': 'reasoning',
          'content': [
            {
              'type': 'reasoning_text',
              'text':
                  'The user wants a weekly summary. We should answer in French.',
            },
          ],
        },
        {
          'type': 'message',
          'role': 'assistant',
          'content': [
            {
              'type': 'output_text',
              'text':
                  '**Resume de la semaine :**\n\n- Revenus : 60 000 CFA\n- Depenses : 10 385 CFA',
            },
          ],
        },
      ],
    });

    expect(answer, isNot(contains('The user wants')));
    expect(answer, contains('Resume de la semaine'));
    expect(answer, contains('60 000 CFA'));
  });
}

ParsedTransaction _parsed({
  required String type,
  required double amount,
  required String rawContent,
  required DateTime date,
}) {
  return ParsedTransaction(
    type: type,
    amount: amount,
    description: rawContent,
    source: 'orange_money',
    rawTitle: 'Orange Money',
    rawContent: rawContent,
    date: date,
  );
}
