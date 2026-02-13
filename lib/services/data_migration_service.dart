import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to migrate data from Hive local storage to Supabase.
/// Used once per user after the app migration from Hive to Supabase.
class DataMigrationService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Check if migration is needed: Hive has data AND Supabase has no transactions
  Future<bool> needsMigration() async {
    try {
      await Hive.initFlutter();

      final txBox = await Hive.openBox('transactions_legacy_check');
      await txBox.close();

      // Try opening the transaction box
      final typedBox = Hive.isBoxOpen('transactions')
          ? Hive.box('transactions')
          : await Hive.openBox('transactions', crashRecovery: false);

      if (typedBox.isEmpty) return false;

      // Check if Supabase already has data for this user
      final response = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', _userId)
          .limit(1);
      return (response as List).isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Migrate all Hive data to Supabase
  Future<void> migrate() async {
    if (!await needsMigration()) return;

    try {
      // 1. Build category name -> UUID map from Supabase
      final supabaseCategories =
          await _client.from('categories').select().eq('user_id', _userId);

      final Map<String, String> categoryMap = {};
      for (final cat in supabaseCategories) {
        categoryMap[cat['name'] as String] = cat['id'] as String;
      }

      // 2. Migrate custom Hive categories not in Supabase
      if (Hive.isBoxOpen('categories') ||
          await _tryOpenBox('categories') != null) {
        final hiveCategoryBox = Hive.box('categories');
        for (var i = 0; i < hiveCategoryBox.length; i++) {
          final hiveCat = hiveCategoryBox.getAt(i);
          if (hiveCat == null) continue;

          final catName = _getField(hiveCat, 'name');
          final catIcon = _getField(hiveCat, 'icon') ?? '0xe148';

          if (catName != null && !categoryMap.containsKey(catName)) {
            try {
              final response = await _client
                  .from('categories')
                  .insert({
                    'user_id': _userId,
                    'name': catName,
                    'icon': catIcon,
                    'is_default': false,
                  })
                  .select()
                  .single();
              categoryMap[catName] = response['id'] as String;
            } catch (_) {
              // Category may already exist (unique constraint)
            }
          }
        }
      }

      // 3. Migrate transactions
      if (Hive.isBoxOpen('transactions') ||
          await _tryOpenBox('transactions') != null) {
        final hiveTxBox = Hive.box('transactions');
        for (var i = 0; i < hiveTxBox.length; i++) {
          final tx = hiveTxBox.getAt(i);
          if (tx == null) continue;

          final type = _getField(tx, 'type') ?? '';
          final category = _getField(tx, 'category') ?? '';
          final montant = _getNumField(tx, 'montant') ?? 0.0;
          final description = _getField(tx, 'description') ?? '';
          final date = _getDateField(tx, 'date') ?? DateTime.now();

          // Map French type to English
          final dbType =
              type.toLowerCase().contains('dép') ? 'deposit' : 'withdrawal';
          final categoryId = categoryMap[category];

          try {
            await _client.from('transactions').insert({
              'user_id': _userId,
              'category_id': categoryId,
              'type': dbType,
              'amount': montant,
              'description': description,
              'date': date.toIso8601String(),
            });
          } catch (_) {}
        }
      }

      // 4. Migrate budgets (spent will be auto-calculated by trigger)
      if (Hive.isBoxOpen('budgets') || await _tryOpenBox('budgets') != null) {
        final hiveBudgetBox = Hive.box('budgets');
        for (var i = 0; i < hiveBudgetBox.length; i++) {
          final budget = hiveBudgetBox.getAt(i);
          if (budget == null) continue;

          final category = _getField(budget, 'category') ?? '';
          final amount = _getNumField(budget, 'amount') ?? 0.0;
          final startDate =
              _getDateField(budget, 'startDate') ?? DateTime.now();
          final endDate = _getDateField(budget, 'endDate') ?? DateTime.now();
          final description = _getField(budget, 'description') ?? '';

          final categoryId = categoryMap[category];

          try {
            await _client.from('budgets').insert({
              'user_id': _userId,
              'category_id': categoryId,
              'amount': amount,
              'start_date': startDate.toIso8601String(),
              'end_date': endDate.toIso8601String(),
              'description': description,
            });
          } catch (_) {}
        }
      }
    } catch (_) {
      // Migration failed silently - user can still use the app with empty data
    }
  }

  Future<Box?> _tryOpenBox(String name) async {
    try {
      return await Hive.openBox(name);
    } catch (_) {
      return null;
    }
  }

  // Helper methods to extract fields from Hive objects (which may be typed or dynamic)
  String? _getField(dynamic obj, String field) {
    try {
      return (obj as dynamic).__getattribute__(field)?.toString();
    } catch (_) {
      try {
        // For HiveObject subclasses, access the field directly
        switch (field) {
          case 'name':
            return obj.name as String?;
          case 'icon':
            return obj.icon as String?;
          case 'type':
            return obj.type as String?;
          case 'category':
            return obj.category as String?;
          case 'description':
            return obj.description as String?;
          default:
            return null;
        }
      } catch (_) {
        return null;
      }
    }
  }

  double? _getNumField(dynamic obj, String field) {
    try {
      switch (field) {
        case 'montant':
          return (obj.montant as num?)?.toDouble();
        case 'amount':
          return (obj.amount as num?)?.toDouble();
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  DateTime? _getDateField(dynamic obj, String field) {
    try {
      switch (field) {
        case 'date':
          return obj.date as DateTime?;
        case 'startDate':
          return obj.startDate as DateTime?;
        case 'endDate':
          return obj.endDate as DateTime?;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}
