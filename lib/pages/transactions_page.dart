// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/pages/edit_transaction_page.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // --- Design system helpers ---
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDark ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);
  Color get _cardColor =>
      _isDark ? AppTheme.darkCardColor : Colors.white;
  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF1A1D29);
  Color get _textSecondary =>
      _isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
  Color get _border => _isDark
      ? AppTheme.darkBorderColor
      : Colors.black.withOpacity(0.04);
  Color get _surfaceColor =>
      _isDark ? AppTheme.darkSurfaceColor : const Color(0xFFF7F8FC);

  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  final Map<String, IconData> _categoryIcons = const {
    'alimentation': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'logement': Icons.home_rounded,
    'loisirs': Icons.sports_esports_rounded,
    'sant\u00e9': Icons.favorite_rounded,
    'sante': Icons.favorite_rounded,
    '\u00e9ducation': Icons.school_rounded,
    'education': Icons.school_rounded,
    'autres': Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Transaction>>(
      stream: SupabaseDataService().transactionsStream,
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Container(
            color: _backgroundColor,
            child: Center(
              child: _buildEmptyState(),
            ),
          );
        }

        // Group transactions by date
        final Map<String, List<Transaction>> grouped = {};
        for (final tx in transactions) {
          final key = DateFormat('dd MMMM yyyy', 'fr_FR').format(tx.date);
          grouped.putIfAbsent(key, () => []).add(tx);
        }
        final sortedKeys = grouped.keys.toList();

        return Container(
          color: _backgroundColor,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: sortedKeys.length,
            itemBuilder: (context, sectionIndex) {
              final dateLabel = sortedKeys[sectionIndex];
              final sectionTransactions = grouped[dateLabel]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sectionIndex > 0) const SizedBox(height: 20),
                  // Section date header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Transactions card group
                  Container(
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(sectionTransactions.length,
                          (index) {
                        final transaction = sectionTransactions[index];
                        final isLast =
                            index == sectionTransactions.length - 1;
                        return _buildTransactionTile(
                          transaction,
                          showDivider: !isLast,
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // --- Empty state ---
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune transaction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premi\u00e8re transaction\npour commencer le suivi',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Single transaction tile ---
  Widget _buildTransactionTile(
    Transaction transaction, {
    bool showDivider = true,
  }) {
    final isDeposit = transaction.isDeposit;
    final color = isDeposit ? _green : _red;
    final categoryIcon =
        _categoryIcons[(transaction.categoryName ?? '').toLowerCase()] ??
            Icons.receipt_rounded;
    final amountFormatted =
        NumberFormat('#,###', 'fr_FR').format(transaction.amount);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionPage(
              transaction: transaction,
              isDarkMode: _isDark,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                // Description + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction.categoryName ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('HH:mm').format(transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount + direction icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDeposit ? '+' : '-'}$amountFormatted',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDeposit
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          size: 12,
                          color: color.withOpacity(0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'CFA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider between items in the same card
          if (showDivider)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                thickness: 1,
                color: _border,
              ),
            ),
        ],
      ),
    );
  }
}
