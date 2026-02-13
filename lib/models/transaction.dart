class Transaction {
  final String? id;
  final String? userId;
  String? categoryId;
  String? categoryName; // Transient - populated from joins
  String type; // 'deposit' or 'withdrawal'
  double amount;
  String description;
  DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    this.userId,
    this.categoryId,
    this.categoryName,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDeposit => type == 'deposit';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories']['name'] as String?)
          : null,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
