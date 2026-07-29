import 'package:flutter/material.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/pending_transaction.dart';
import 'package:spendwise/services/notification_transaction_service.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/utils/app_format.dart';

class PendingTransactionsPage extends StatefulWidget {
  const PendingTransactionsPage({super.key});

  @override
  State<PendingTransactionsPage> createState() =>
      _PendingTransactionsPageState();
}

class _PendingTransactionsPageState extends State<PendingTransactionsPage> {
  final _service = NotificationTransactionService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<int>(
        stream: _service.pendingCountStream,
        initialData: _service.pendingCount,
        builder: (context, _) => Scaffold(
              backgroundColor: context.appBgColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: context.appTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  l10n.pendingTransactions,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
                actions: [
                  if (_service.getPendingTransactions().isNotEmpty)
                    TextButton(
                      onPressed: _approveAll,
                      child: Text(
                        l10n.approveAll,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              body: _buildBody(l10n),
            ));
  }

  Widget _buildBody(AppLocalizations l10n) {
    final pending = _service.getPendingTransactions();

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: context.appTextSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPendingTransactions,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final tx = pending[index];
        return _buildPendingItem(tx, l10n);
      },
    );
  }

  Widget _buildPendingItem(PendingTransaction tx, AppLocalizations l10n) {
    final isDeposit = tx.type == 'deposit';
    final amountColor = isDeposit ? AppTheme.successColor : AppTheme.errorColor;
    final amountPrefix = isDeposit ? '+' : '-';

    return Dismissible(
      key: Key(tx.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.successColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        try {
          if (direction == DismissDirection.startToEnd) {
            final approved = await _service.approvePending(tx.id);
            if (!approved) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.processingError),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              return false;
            }
          } else {
            _service.rejectPending(tx.id);
          }
          return true; // laisse le widget disparaître visuellement
        } catch (e) {
          debugPrint('PendingTransactionsPage.confirmDismiss: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.processingError),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          return false; // ne pas supprimer visuellement si erreur
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Row(
          children: [
            // Source icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sourceColor(tx.source).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _sourceIcon(tx.source),
                color: _sourceColor(tx.source),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sourceLabel(tx.source)} · ${formatDate(context, 'dd/MM HH:mm', tx.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Text(
              '$amountPrefix${formatMoney(context, tx.amount, withCurrency: false)} ${appCurrency(context)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAll() async {
    final failedCount = await _service.approveAll();
    if (!mounted || failedCount == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.processingError),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _sourceIcon(String source) {
    return source == 'wave' ? Icons.waves_rounded : Icons.phone_android_rounded;
  }

  Color _sourceColor(String source) {
    return source == 'wave' ? const Color(0xFF1DC1EC) : const Color(0xFFFF6600);
  }

  String _sourceLabel(String source) {
    return source == 'wave' ? 'Wave' : 'Orange Money';
  }
}
