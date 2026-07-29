import 'package:flutter/material.dart';
import 'package:spendwise/theme/app_theme.dart';

/// Shared empty-state widget used across all pages.
///
/// [inCard] wraps the content in a rounded card container (dashboard style).
/// Without [inCard], renders as a centered column (list/page style).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool inCard;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.iconBgColor,
    this.inCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1D29);
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.04);
    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : const Color(0xFFF7F8FC);

    final resolvedIconColor = iconColor ?? textSecondary;
    final resolvedIconBg = iconBgColor ?? surfaceColor;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: resolvedIconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: resolvedIconColor),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 20),
          action!,
        ],
      ],
    );

    if (inCard) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: content,
      ),
    );
  }
}
