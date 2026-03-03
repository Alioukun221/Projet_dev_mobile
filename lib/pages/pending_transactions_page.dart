import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/pending_transaction.dart';
import 'package:spendwise/services/notification_transaction_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class PendingTransactionsPage extends StatefulWidget {
  final bool isDarkMode;
  const PendingTransactionsPage({super.key, required this.isDarkMode});

  @override
  State<PendingTransactionsPage> createState() =>
      _PendingTransactionsPageState();
}

class _PendingTransactionsPageState extends State<PendingTransactionsPage> {
  final _service = NotificationTransactionService();

  bool get _isDarkMode => widget.isDarkMode;
  Color get _bgColor =>
      _isDarkMode ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);
  Color get _cardColor =>
      _isDarkMode ? AppTheme.darkCardColor : Colors.white;
  Color get _textPrimary =>
      _isDarkMode ? Colors.white : const Color(0xFF1A1D29);
  Color get _textSecondary =>
      _isDarkMode ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode
      ? AppTheme.darkBorderColor
      : Colors.black.withOpacity(0.04);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.pendingTransactions,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
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
    );
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
              color: _textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPendingTransactions,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
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
    final formatter = NumberFormat('#,###', 'fr_FR');

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
            await _service.approvePending(tx.id);
          } else {
            _service.rejectPending(tx.id);
          }
          if (mounted) setState(() {});
          return true; // laisse le widget disparaître visuellement
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Erreur lors du traitement'),
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
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
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
                      color: _textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sourceLabel(tx.source)} · ${DateFormat('dd/MM HH:mm').format(tx.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Text(
              '$amountPrefix${formatter.format(tx.amount.toInt())} F',
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
    await _service.approveAll();
    if (mounted) setState(() {});
  }

  IconData _sourceIcon(String source) {
    return source == 'wave'
        ? Icons.waves_rounded
        : Icons.phone_android_rounded;
  }

  Color _sourceColor(String source) {
    return source == 'wave'
        ? const Color(0xFF1DC1EC)
        : const Color(0xFFFF6600);
  }

  String _sourceLabel(String source) {
    return source == 'wave' ? 'Wave' : 'Orange Money';
  }
}
