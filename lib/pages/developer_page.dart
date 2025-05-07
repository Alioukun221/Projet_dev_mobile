import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text("À propos du développeur"),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  'assets/images/dev_avatar.jpg'), // Assure-toi que cette image existe
            ),
            const SizedBox(height: 16),
            const Text(
              "Mouhamadou Aliou BA",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Élève Ingénieur en Informatique à l'EPT",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.blue),
              title: const Text("bmouhamadoualiou@ept.sn"),
              onTap: () => _launchURL("mailto:bmouhamadoualiou@ept.sn"),
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.green),
              title: const Text("github.com/Alioukun221"),
              onTap: () => _launchURL("https://github.com/Alioukun221"),
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Colors.blueAccent),
              title: const Text("linkedin.com/in/tonprofil"),
              onTap: () => _launchURL("https://linkedin.com/in/tonprofil"),
            ),
            const Spacer(),
            const Text(
              "Merci d’utiliser SpendWise !",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
