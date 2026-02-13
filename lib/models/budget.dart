class Budget {
  final String? id;
  final String? userId;
  String? categoryId;
  String? categoryName; // Transient - populated from joins
  double amount;
  DateTime startDate;
  DateTime endDate;
  double spent;
  String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Budget({
    this.id,
    this.userId,
    this.categoryId,
    this.categoryName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spent = 0,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  double get remaining => amount - spent;
  double get progress => amount > 0 ? (spent / amount) * 100 : 0;
  bool get isOverBudget => spent > amount;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories']['name'] as String?)
          : null,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      description: json['description'] as String? ?? '',
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
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
    };
  }
}
