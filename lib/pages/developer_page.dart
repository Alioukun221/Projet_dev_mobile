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
              title: 'Gestion des transactions',
              description: 'Ajoutez, modifiez et supprimez vos dépenses et revenus avec catégorisation',
            ),
            _buildFeatureItem(
              icon: Icons.dashboard_outlined,
              title: 'Tableau de bord',
              description: 'Vue d\'ensemble de vos finances avec solde, dépôts et retraits',
            ),
            _buildFeatureItem(
              icon: Icons.category_outlined,
              title: 'Gestion des catégories',
              description: 'Catégories par défaut et personnalisées pour organiser vos transactions',
            ),
            _buildFeatureItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budgets',
              description: 'Créez et suivez vos budgets par catégorie avec alertes',
            ),
            _buildFeatureItem(
              icon: Icons.bar_chart_outlined,
              title: 'Statistiques détaillées',
              description: 'Graphiques en barres et circulaires pour analyser vos dépenses et revenus',
            ),
            _buildFeatureItem(
              icon: Icons.calendar_today_outlined,
              title: 'Filtres temporels',
              description: 'Analysez vos finances par jour, semaine, mois ou année',
            ),
            _buildFeatureItem(
              icon: Icons.dark_mode_outlined,
              title: 'Thème personnalisable',
              description: 'Mode clair et sombre pour un confort visuel optimal',
            ),
            
            _buildFeatureItem(
              icon: Icons.storage_outlined,
              title: 'Stockage local',
              description: 'Données sauvegardées localement pour une confidentialité totale',
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
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
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
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      InkWell(
                        onTap: () {
                          final Uri githubUri = Uri.parse('https://github.com/Alioukun221');
                          launchUrl(
                            githubUri,
                            mode: LaunchMode.platformDefault,
                          );
                        },
                        child: Text(
                          'https://github.com/Alioukun221',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
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
