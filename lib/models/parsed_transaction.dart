class ParsedTransaction {
  final String type; // 'deposit' or 'withdrawal'
  final double amount;
  final String description;
  final String source; // 'wave' or 'orange_money'
  final String rawTitle;
  final String rawContent;
  final DateTime date;

  ParsedTransaction({
    required this.type,
    required this.amount,
    required this.description,
    required this.source,
    required this.rawTitle,
    required this.rawContent,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        'description': description,
        'source': source,
        'raw_title': rawTitle,
        'raw_content': rawContent,
        'date': date.toIso8601String(),
      };

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      source: json['source'] as String,
      rawTitle: json['raw_title'] as String,
      rawContent: json['raw_content'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
