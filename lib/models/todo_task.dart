class TodoTask {
  final String? id;
  final String? userId;
  final String title;
  final double amount;
  final String type; // 'deposit' or 'withdrawal'
  final String? categoryId;
  String? categoryName; // Transient - populated from joins
  final DateTime dueDate;
  final String recurrence; // 'none', 'weekly', 'monthly'
  final bool isCompleted;
  final DateTime? completedAt;
  final String? transactionId;
  final DateTime? createdAt;

  TodoTask({
    this.id,
    this.userId,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    this.categoryName,
    required this.dueDate,
    this.recurrence = 'none',
    this.isCompleted = false,
    this.completedAt,
    this.transactionId,
    this.createdAt,
  });

  bool get isDeposit => type == 'deposit';
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !isCompleted;

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null
          ? (json['categories']['name'] as String?)
          : null,
      dueDate: DateTime.parse(json['due_date'] as String),
      recurrence: json['recurrence'] as String? ?? 'none',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      transactionId: json['transaction_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'due_date': dueDate.toIso8601String(),
      'recurrence': recurrence,
      'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }
}
