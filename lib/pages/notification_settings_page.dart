import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/models/category.dart' as models;
import 'package:spendwise/services/local_cache_service.dart';
import 'package:spendwise/services/notification_transaction_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  final bool isDarkMode;
  const NotificationSettingsPage({super.key, required this.isDarkMode});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _cache = LocalCacheService.instance;
  bool _hasPermission = false;
  List<models.Category> _categories = [];

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
  void initState() {
    super.initState();
    _checkPermission();
    _loadCategories();
  }

  Future<void> _checkPermission() async {
    final granted =
        await NotificationListenerService.isPermissionGranted();
    if (mounted) setState(() => _hasPermission = granted);
  }

  Future<void> _loadCategories() async {
    final cats = await SupabaseDataService().getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _requestPermission() async {
    await NotificationListenerService.requestPermission();
    await _checkPermission();
  }

  void _toggleEnabled(bool value) {
    setState(() => _cache.isNotificationListeningEnabled = value);
    if (value && _hasPermission) {
      NotificationTransactionService().startListening();
    } else {
      NotificationTransactionService().stopListening();
    }
  }

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
          l10n.notificationSettings,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Permission status
          _buildSection(
            icon: _hasPermission
                ? Icons.check_circle_rounded
                : Icons.warning_rounded,
            iconColor: _hasPermission ? AppTheme.successColor : Colors.orange,
            title: _hasPermission
                ? l10n.notificationPermissionGranted
                : l10n.notificationPermissionRequired,
            trailing: _hasPermission
                ? null
                : TextButton(
                    onPressed: _requestPermission,
                    child: Text(
                      l10n.grantPermission,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Master toggle
          _buildSwitchTile(
            icon: Icons.notifications_active_rounded,
            iconColor: AppTheme.primaryColor,
            title: l10n.enableNotificationListening,
            value: _cache.isNotificationListeningEnabled,
            onChanged: _hasPermission ? _toggleEnabled : null,
          ),
          const SizedBox(height: 16),

          // Mode selection
          _buildCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.notificationModeTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
              RadioListTile<String>(
                title: Text(
                  l10n.notificationModeAuto,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.notificationModeAutoDesc,
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
                value: 'auto',
                groupValue: _cache.notificationMode,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) {
                  if (v != null) setState(() => _cache.notificationMode = v);
                },
              ),
              RadioListTile<String>(
                title: Text(
                  l10n.notificationModeConfirmation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.notificationModeConfirmationDesc,
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
                value: 'confirmation',
                groupValue: _cache.notificationMode,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) {
                  if (v != null) setState(() => _cache.notificationMode = v);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 16),

          // Per-service toggles
          _buildSwitchTile(
            icon: Icons.waves_rounded,
            iconColor: const Color(0xFF1DC1EC),
            title: 'Wave',
            value: _cache.isWaveEnabled,
            onChanged: (v) => setState(() => _cache.isWaveEnabled = v),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFFFF6600),
            title: 'Orange Money',
            value: _cache.isOrangeMoneyEnabled,
            onChanged: (v) => setState(() => _cache.isOrangeMoneyEnabled = v),
          ),
          const SizedBox(height: 16),

          // Default categories
          if (_categories.isNotEmpty) ...[
            _buildCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.defaultCategories,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
                _buildCategoryDropdown(
                  label: l10n.deposit,
                  currentId: _cache.defaultDepositCategoryId,
                  onChanged: (id) =>
                      setState(() => _cache.defaultDepositCategoryId = id),
                ),
                _buildCategoryDropdown(
                  label: l10n.withdrawal,
                  currentId: _cache.defaultWithdrawalCategoryId,
                  onChanged: (id) =>
                      setState(() => _cache.defaultWithdrawalCategoryId = id),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
            activeTrackColor: AppTheme.accentColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    required String? currentId,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _categories.any((c) => c.id == currentId)
                    ? currentId
                    : null,
                isDense: true,
                dropdownColor: _cardColor,
                borderRadius: BorderRadius.circular(14),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                hint: Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Auto',
                      style: TextStyle(color: _textSecondary),
                    ),
                  ),
                  ..._categories.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
