import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendwise/pages/home_page.dart'; // Importez la page principale de l'app

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Pour éviter l'orientation horizontale
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Naviguer vers la page principale après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'SpendWise',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(), // Optionnel : Affiche un indicateur de chargement
          ],
        ),
      ),
    );
  }
}
