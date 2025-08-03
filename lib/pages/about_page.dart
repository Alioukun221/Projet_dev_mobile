import 'package:flutter/material.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendwise/theme/app_theme.dart';

class AboutPage extends StatefulWidget {
  final bool isDarkMode;
  const AboutPage({super.key, required this.isDarkMode});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // Fonction pour ouvrir un lien
  // void _launchURL(String url) async {
  //   if (await canLaunchUrl(Uri.parse(url))) {
  //     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  //   }
  // }

  bool get _isDarkMode => widget.isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 2,
        title: Text(
          AppLocalizations.of(context)!.about,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
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
                      color: AppTheme.primaryColor,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusL),
                      boxShadow: AppTheme.shadowM,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: TextStyle(
                      fontSize: AppTheme.titleLarge.fontSize,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Version 1.0.0',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Description
            Text(
              AppLocalizations.of(context)!.about,
              style: TextStyle(
                fontSize: AppTheme.titleLarge.fontSize,
                fontWeight: FontWeight.w400,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              AppLocalizations.of(context)!.appDescription,
              style: TextStyle(
                fontSize: AppTheme.bodyLarge.fontSize,
                fontWeight: FontWeight.w300,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Features
            Text(
              AppLocalizations.of(context)!.features,
              style: TextStyle(
                fontSize: AppTheme.titleLarge.fontSize,
                fontWeight: FontWeight.w400,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildFeatureItem(
                icon: Icons.add_circle_outline,
                title:
                    AppLocalizations.of(context)!.featureTransactionManagement,
                description: AppLocalizations.of(context)!
                    .featureTransactionDescription),
            _buildFeatureItem(
                icon: Icons.dashboard_outlined,
                title: AppLocalizations.of(context)!.featureDashboard,
                description:
                    AppLocalizations.of(context)!.featureDashboardDescription),
            _buildFeatureItem(
                icon: Icons.category_outlined,
                title: AppLocalizations.of(context)!.featureCategoryManagement,
                description:
                    AppLocalizations.of(context)!.featureCategoryDescription),
            _buildFeatureItem(
              icon: Icons.account_balance_wallet_outlined,
              title: AppLocalizations.of(context)!.featureBudgets,
              description:
                  AppLocalizations.of(context)!.featureBudgetsDescription,
            ),
            _buildFeatureItem(
                icon: Icons.bar_chart_outlined,
                title: AppLocalizations.of(context)!.featureStatistics,
                description:
                    AppLocalizations.of(context)!.featureStatisticsDescription),
            _buildFeatureItem(
              icon: Icons.calendar_today_outlined,
              title: AppLocalizations.of(context)!.featureDateFilters,
              description:
                  AppLocalizations.of(context)!.featureDateFiltersDescription,
            ),

            _buildFeatureItem(
                icon: Icons.storage_outlined,
                title: AppLocalizations.of(context)!.featureLocalStorage,
                description: AppLocalizations.of(context)!
                    .featureLocalStorageDescription),
            _buildFeatureItem(
              icon: Icons.dark_mode_outlined,
              title: AppLocalizations.of(context)!.featureTheme,
              description:
                  AppLocalizations.of(context)!.featureThemeDescription,
            ),
            _buildFeatureItem(
              icon: Icons.language,
              title: AppLocalizations.of(context)!.featureLanguage,
              description:
                  AppLocalizations.of(context)!.featureLanguageDescription,
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Developer Info
            Text(
              AppLocalizations.of(context)!.developer,
              style: TextStyle(
                fontSize: AppTheme.titleLarge.fontSize,
                fontWeight: FontWeight.w400,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color.fromARGB(255, 72, 71, 71)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                boxShadow: AppTheme.shadowS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.developerTitle,
                    style: TextStyle(
                      fontSize: AppTheme.titleMedium.fontSize,
                      fontWeight: FontWeight.w300,
                      color: _isDarkMode
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    AppLocalizations.of(context)!.developerSubtitle,
                    style: AppTheme.bodyMedium.copyWith(
                      color: const Color.fromARGB(255, 52, 51, 51),
                      fontSize: AppTheme.bodyMedium.fontSize,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      InkWell(
                        onTap: () {
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'bmouhamadoualiou@ept.sn',
                            queryParameters: {
                              'subject': 'À propos de SpendWise',
                            },
                          );
                          launchUrl(emailLaunchUri);
                        },
                        child: Text(
                          'bmouhamadoualiou@ept.sn',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.secondaryColor,
                            fontSize: AppTheme.bodyMedium.fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      Icon(
                        Icons.code,
                        size: 20,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      InkWell(
                        onTap: () {
                          final Uri githubUri =
                              Uri.parse('https://github.com/Alioukun221');
                          launchUrl(
                            githubUri,
                            mode: LaunchMode.platformDefault,
                          );
                        },
                        child: Text(
                          'https://github.com/Alioukun221',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.secondaryColor,
                            fontSize: AppTheme.bodyMedium.fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Copyright
            Center(
              child: Text(
                AppLocalizations.of(context)!.copyright,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color.fromARGB(255, 72, 71, 71)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        boxShadow: AppTheme.shadowM,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.titleMedium.fontSize,
                    fontWeight: FontWeight.w400,
                    color:
                        _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: _isDarkMode
                        ? const Color.fromARGB(255, 158, 156, 156)
                        : AppTheme.textSecondaryColor,
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
