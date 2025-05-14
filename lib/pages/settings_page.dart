import 'package:flutter/material.dart';
import 'package:spendwise/theme/app_theme.dart';
import 'package:spendwise/pages/developer_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _weeklyReport = true;
  bool _budgetAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Apparence
            _buildSection(
              title: 'Apparence',
              icon: Icons.palette_outlined,
              children: [
                SwitchListTile(
                  title: const Text('Mode sombre'),
                  subtitle: const Text('Activer le thème sombre'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Section Notifications
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
              children: [
                SwitchListTile(
                  title: const Text('Activer les notifications'),
                  subtitle: const Text('Recevoir des notifications de l\'application'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                if (_notificationsEnabled) ...[
                  SwitchListTile(
                    title: const Text('Rapport hebdomadaire'),
                    subtitle: const Text('Recevoir un résumé hebdomadaire de vos dépenses'),
                    value: _weeklyReport,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReport = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Alertes de budget'),
                    subtitle: const Text('Être notifié lorsque vous approchez de votre limite de budget'),
                    value: _budgetAlerts,
                    onChanged: (value) {
                      setState(() {
                        _budgetAlerts = value;
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Section Données
            _buildSection(
              title: 'Données',
              icon: Icons.storage_outlined,
              children: [
                ListTile(
                  title: const Text('Exporter les données'),
                  subtitle: const Text('Sauvegarder vos données au format CSV'),
                  trailing: const Icon(Icons.download_outlined),
                  onTap: () {
                    // TODO: Implémenter l'export des données
                  },
                ),
                ListTile(
                  title: const Text('Effacer toutes les données'),
                  subtitle: const Text('Supprimer toutes les données de l\'application'),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir supprimer toutes les données ? Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implémenter la suppression des données
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Section À propos
            _buildSection(
              title: 'À propos',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  title: const Text('Développeur'),
                  subtitle: const Text('Mouhamadou Aliou BA'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeveloperPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Politique de confidentialité'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Ouvrir la politique de confidentialité
                  },
                ),
                ListTile(
                  title: const Text('Conditions d\'utilisation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Ouvrir les conditions d'utilisation
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        boxShadow: AppTheme.shadowS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  title,
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
} 