import 'package:hive/hive.dart';

part 'transaction.g.dart'; // Généré automatiquement

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String type; // 'dépôt' ou 'retrait'

  @HiveField(1)
  double montant;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  Transaction({
    required this.type,
    required this.montant,
    required this.description,
    required this.date,
  });
}
