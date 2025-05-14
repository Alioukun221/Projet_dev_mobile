import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime startDate;

  @HiveField(3)
  DateTime endDate;

  @HiveField(4)
  double spent;

  @HiveField(5)
  String description;

  Budget({
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spent = 0,
    this.description = '',
  });

  double get remaining => amount - spent;
  double get progress => (spent / amount) * 100;
  bool get isOverBudget => spent > amount;
} 