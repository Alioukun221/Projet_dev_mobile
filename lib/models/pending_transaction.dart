import 'dart:math';
import 'package:spendwise/models/parsed_transaction.dart';

class PendingTransaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String source;
  final String rawTitle;
  final String rawContent;
  final DateTime date;
  final DateTime createdAt;
  String status; // 'pending', 'approved', 'rejected'

  PendingTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.source,
    required this.rawTitle,
    required this.rawContent,
    required this.date,
    required this.createdAt,
    this.status = 'pending',
  });

  factory PendingTransaction.fromParsed(ParsedTransaction parsed) {
    return PendingTransaction(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}',
      type: parsed.type,
      amount: parsed.amount,
      description: parsed.description,
      source: parsed.source,
      rawTitle: parsed.rawTitle,
      rawContent: parsed.rawContent,
      date: parsed.date,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'description': description,
        'source': source,
        'raw_title': rawTitle,
        'raw_content': rawContent,
        'date': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'status': status,
      };

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    return PendingTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      source: json['source'] as String,
      rawTitle: json['raw_title'] as String,
      rawContent: json['raw_content'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}
