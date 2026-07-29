import 'package:flutter/material.dart';
import 'package:spendwise/constants/app_colors.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _primaryBlue = Color(0xFF005EFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorderColor),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: context.appTextPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.about,
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/new_logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            Text(
              AppLocalizations.of(context)!.about,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.appDescription,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: context.appTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Features
            Text(
              AppLocalizations.of(context)!.features,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(context,
                icon: Icons.add_circle_outline,
                title:
                    AppLocalizations.of(context)!.featureTransactionManagement,
                description: AppLocalizations.of(context)!
                    .featureTransactionDescription),
            _buildFeatureItem(context,
                icon: Icons.dashboard_outlined,
                title: AppLocalizations.of(context)!.featureDashboard,
                description:
                    AppLocalizations.of(context)!.featureDashboardDescription),
            _buildFeatureItem(context,
                icon: Icons.category_outlined,
                title: AppLocalizations.of(context)!.featureCategoryManagement,
                description:
                    AppLocalizations.of(context)!.featureCategoryDescription),
            _buildFeatureItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: AppLocalizations.of(context)!.featureBudgets,
              description:
                  AppLocalizations.of(context)!.featureBudgetsDescription,
            ),
            _buildFeatureItem(context,
                icon: Icons.bar_chart_outlined,
                title: AppLocalizations.of(context)!.featureStatistics,
                description:
                    AppLocalizations.of(context)!.featureStatisticsDescription),
            _buildFeatureItem(
              context,
              icon: Icons.calendar_today_outlined,
              title: AppLocalizations.of(context)!.featureDateFilters,
              description:
                  AppLocalizations.of(context)!.featureDateFiltersDescription,
            ),

            _buildFeatureItem(context,
                icon: Icons.storage_outlined,
                title: AppLocalizations.of(context)!.featureLocalStorage,
                description: AppLocalizations.of(context)!
                    .featureLocalStorageDescription),
            _buildFeatureItem(
              context,
              icon: Icons.wifi_off_rounded,
              title: AppLocalizations.of(context)!.featureOfflineSync,
              description:
                  AppLocalizations.of(context)!.featureOfflineSyncDescription,
            ),
            _buildFeatureItem(
              context,
              icon: Icons.task_alt_rounded,
              title: AppLocalizations.of(context)!.featureTodos,
              description:
                  AppLocalizations.of(context)!.featureTodosDescription,
            ),
            _buildFeatureItem(
              context,
              icon: Icons.sms_outlined,
              title: AppLocalizations.of(context)!.featureNotifSms,
              description:
                  AppLocalizations.of(context)!.featureNotifSmsDescription,
            ),
            _buildFeatureItem(
              context,
              icon: Icons.dark_mode_outlined,
              title: AppLocalizations.of(context)!.featureTheme,
              description:
                  AppLocalizations.of(context)!.featureThemeDescription,
            ),
            _buildFeatureItem(
              context,
              icon: Icons.language,
              title: AppLocalizations.of(context)!.featureLanguage,
              description:
                  AppLocalizations.of(context)!.featureLanguageDescription,
            ),

            const SizedBox(height: 28),

            // Developer Info
            Text(
              AppLocalizations.of(context)!.developer,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appCardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: _primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.developerTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.appTextPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppLocalizations.of(context)!.developerSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: context.appBorderColor, height: 1),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'bmouhamadoualiou@ept.sn',
                        queryParameters: {
                          'subject': 'A propos de SpendWise',
                        },
                      );
                      launchUrl(emailLaunchUri);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: _primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'bmouhamadoualiou@ept.sn',
                            style: TextStyle(
                              fontSize: 14,
                              color: _primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      final Uri githubUri =
                          Uri.parse('https://github.com/Alioukun221');
                      launchUrl(
                        githubUri,
                        mode: LaunchMode.platformDefault,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.code,
                              size: 18,
                              color: _primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'github.com/Alioukun221',
                            style: TextStyle(
                              fontSize: 14,
                              color: _primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Copyright
            Center(
              child: Text(
                AppLocalizations.of(context)!.copyright,
                style: TextStyle(
                  fontSize: 13,
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.appTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
