import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendwise/pages/home_page.dart'; // Importez la page principale de l'app
import 'package:spendwise/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Pour éviter l'orientation horizontale
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Naviguer vers la page principale après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                  boxShadow: AppTheme.shadowM,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // App Name
            FadeTransition(
              opacity: _animation,
              child: Text(
                'SpendWise',
                style: AppTheme.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),

            // Tagline
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Gérez vos finances en toute simplicité',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
