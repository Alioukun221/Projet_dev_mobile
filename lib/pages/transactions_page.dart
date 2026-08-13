// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:spendwise/constants/category_icons.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/pages/edit_transaction_page.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/utils/app_format.dart';
import 'package:spendwise/widgets/app_empty_state.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _visibleCount = 50;
  static const _pageSize = 50;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Transaction>>(
      stream: SupabaseDataService().transactionsStream,
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        if (!SupabaseDataService().isFirstLoadComplete) {
          return Container(
            color: context.appBgColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (transactions.isEmpty) {
          return Container(
            color: context.appBgColor,
            child: Center(
              child: _buildEmptyState(),
            ),
          );
        }

        final visible = transactions.take(_visibleCount).toList();
        final hasMore = transactions.length > _visibleCount;

        // Group transactions by date
        final Map<String, List<Transaction>> grouped = {};
        for (final tx in visible) {
          final key = formatDate(context, 'dd MMMM yyyy', tx.date);
          grouped.putIfAbsent(key, () => []).add(tx);
        }
        final sortedKeys = grouped.keys.toList();

        return Container(
          color: context.appBgColor,
          child: Column(
            children: [
              // Export header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${transactions.length} transaction${transactions.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  // 120 px degagent la barre de navigation flottante de
                  // l'accueil, plus la hauteur de la barre systeme Android.
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, 120 + MediaQuery.of(context).padding.bottom),
                  itemCount: sortedKeys.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, sectionIndex) {
                    if (hasMore && sectionIndex == sortedKeys.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _visibleCount += _pageSize),
                            child: Text(
                              'Voir plus',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
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
                              color: context.appTextSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        // Transactions card group
                        Container(
                          decoration: BoxDecoration(
                            color: context.appCardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.appBorderColor),
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
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyState(
      icon: Icons.receipt_long_rounded,
      title: l10n.noTransactions,
      subtitle: l10n.addFirstTransaction,
      inCard: true,
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
        CategoryIcons.map[(transaction.categoryName ?? '').toLowerCase()] ??
            Icons.receipt_rounded;
    final amountFormatted =
        formatMoney(context, transaction.amount, withCurrency: false);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionPage(
              transaction: transaction,
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
                          color: context.appTextPrimary,
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
                              color: context.appSurfaceColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction.categoryName ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: context.appTextSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            formatDate(context, 'HH:mm', transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appTextSecondary,
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
                          appCurrency(context),
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
                color: context.appBorderColor,
              ),
            ),
        ],
      ),
    );
  }
}
