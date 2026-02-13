import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _cardColor => _isDark ? AppTheme.darkCardColor : Colors.white;
  Color get _surfaceColor =>
      _isDark ? AppTheme.darkSurfaceColor : const Color(0xFFF7F8FC);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1A1D29);
  Color get _textSecondary =>
      _isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
  Color get _border =>
      _isDark ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.04);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Transaction>>(
      stream: SupabaseDataService().transactionsStream,
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? [];

        double total = 0;
        double income = 0;
        double expenses = 0;

        // Already sorted by date desc from service
        List<Transaction> recentTransactions =
            allTransactions.take(5).toList();

        for (var tx in allTransactions) {
          if (tx.isDeposit) {
            income += tx.amount;
            total += tx.amount;
          } else {
            expenses += tx.amount;
            total -= tx.amount;
          }
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(total, income, expenses),
                        const SizedBox(height: 20),
                        _buildIncomeExpenseRow(income, expenses),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          AppLocalizations.of(context)!.lastTransactions,
                        ),
                        const SizedBox(height: 5),
                        if (recentTransactions.isEmpty)
                          _buildEmptyState(
                            Icons.receipt_long_rounded,
                            AppLocalizations.of(context)!.emptyTransaction,
                          )
                        else
                          ...recentTransactions.map((tx) => Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                                child: _buildTransactionTile(tx),
                              )),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          AppLocalizations.of(context)!.graphicView,
                        ),
                        const SizedBox(height: 12),
                        if (income == 0 && expenses == 0)
                          _buildEmptyState(
                            Icons.analytics_rounded,
                            AppLocalizations.of(context)!.noDataDescription,
                          )
                        else
                          _buildPieChart(income, expenses),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(double total, double income, double expenses) {
    final isPositive = total >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2555),
            Color(0xFF0F1640),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005EFF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.balance,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? '+' : '-',
                      style: TextStyle(
                        color:
                            isPositive ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${NumberFormat('#,###', 'fr_FR').format(total.abs())} CFA',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.summaryFinance,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          // Mini progress bar income vs expenses
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  Expanded(
                    flex: income > 0 ? income.toInt() : 1,
                    child:
                        Container(color: Colors.greenAccent.withOpacity(0.8)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: expenses > 0 ? expenses.toInt() : 1,
                    child: Container(color: Colors.redAccent.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(double income, double expenses) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            icon: Icons.south_west_rounded,
            label: AppLocalizations.of(context)!.deposit,
            amount: income,
            color: const Color(0xFF22C55E),
            bgColor: const Color(0xFF22C55E).withOpacity(0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            icon: Icons.north_east_rounded,
            label: AppLocalizations.of(context)!.withdrawal,
            amount: expenses,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFEF4444).withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormat('#,###', 'fr_FR').format(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: _textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    final isDeposit = tx.isDeposit;
    final color = isDeposit ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    final Map<String, IconData> categoryIcons = {
      'alimentation': Icons.restaurant_rounded,
      'transport': Icons.directions_car_rounded,
      'logement': Icons.home_rounded,
      'loisirs': Icons.sports_esports_rounded,
      'santé': Icons.favorite_rounded,
      'sante': Icons.favorite_rounded,
      'éducation': Icons.school_rounded,
      'education': Icons.school_rounded,
      'autres': Icons.more_horiz_rounded,
    };
    final categoryIcon =
        categoryIcons[(tx.categoryName ?? '').toLowerCase()] ?? Icons.receipt_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        // borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: _border),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.02),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
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
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 6, vertical: 2),
                      //   decoration: BoxDecoration(
                      //     color: _surfaceColor,
                      //     borderRadius: BorderRadius.circular(4),
                      //   ),
                      //   child: Text(
                      //     tx.category,
                      //     style: TextStyle(
                      //       fontSize: 11,
                      //       fontWeight: FontWeight.w500,
                      //       color: _textSecondary,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM', 'fr_FR').format(tx.date),
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
            Text(
              '${isDeposit ? '+' : '-'}${NumberFormat('#,###', 'fr_FR').format(tx.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double income, double expenses) {
    final total = income + expenses;
    final incomePercent = (income / total * 100).toStringAsFixed(0);
    final expensePercent = (expenses / total * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: [
                      PieChartSectionData(
                        value: income,
                        color: const Color(0xFF22C55E),
                        radius: _touchedPieIndex == 0 ? 55 : 45,
                        title: '$incomePercent%',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: _touchedPieIndex == 0 ? 14 : 12,
                        ),
                      ),
                      PieChartSectionData(
                        value: expenses,
                        color: const Color(0xFFEF4444),
                        radius: _touchedPieIndex == 1 ? 55 : 45,
                        title: '$expensePercent%',
                        titleStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: _touchedPieIndex == 1 ? 14 : 12,
                        ),
                      ),
                    ],
                    centerSpaceRadius: 55,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat('#,###', 'fr_FR').format(income - expenses),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'CFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                AppLocalizations.of(context)!.deposit,
                const Color(0xFF22C55E),
                income,
              ),
              Container(
                width: 1,
                height: 30,
                color: _border,
              ),
              _buildLegendItem(
                AppLocalizations.of(context)!.withdrawal,
                const Color(0xFFEF4444),
                expenses,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat('#,###', 'fr_FR').format(amount)} CFA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}
