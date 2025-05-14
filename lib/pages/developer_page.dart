import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendwise/theme/app_theme.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  // Fonction pour ouvrir un lien
  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
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
                    'SpendWise',
                    style: AppTheme.headlineMedium,
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
              'À propos',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'SpendWise est une application de gestion de finances personnelles qui vous permet de suivre vos dépenses et vos revenus en toute simplicité.',
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Features
            Text(
              'Fonctionnalités',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildFeatureItem(
              icon: Icons.add_circle_outline,
              title: 'Ajout de transactions',
              description: 'Enregistrez facilement vos dépenses et vos revenus',
            ),
            _buildFeatureItem(
              icon: Icons.pie_chart_outline,
              title: 'Statistiques',
              description:
                  'Visualisez vos finances avec des graphiques détaillés',
            ),
            _buildFeatureItem(
              icon: Icons.history,
              title: 'Historique',
              description:
                  'Consultez l\'historique complet de vos transactions',
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Developer Info
            Text(
              'Développeur',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                boxShadow: AppTheme.shadowS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mouhamadou Aliou BA',
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Élève ingénieur a l\'EPT ',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'votre.email@example.com',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
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
                '© 2024 SpendWise. Tous droits réservés.',
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
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        boxShadow: AppTheme.shadowS,
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
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
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
