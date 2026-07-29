import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/pages/auth/welcome_page.dart';
import 'package:spendwise/pages/home_page.dart';
import 'package:spendwise/providers/locale_provider.dart';
import 'package:spendwise/providers/profile_provider.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/services/notification_transaction_service.dart';
import 'package:spendwise/services/sms_transaction_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/services/todo_notification_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Check auth state after splash animation
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _navigateBasedOnAuth();
    });
  }

  void _navigateBasedOnAuth() async {
    final isLoggedIn = AuthService().isLoggedIn;

    if (isLoggedIn) {
      try {
        await SupabaseDataService().init();
        await NotificationTransactionService().init();
        await SmsTransactionService().init();

        final todos = await SupabaseDataService().getTodos();
        await TodoNotificationService().init();
        await TodoNotificationService().rescheduleAll(todos);

        final profileData = await AuthService().getProfile();
        if (mounted) {
          Provider.of<ProfileProvider>(context, listen: false)
              .applyFromData(profileData);
          Provider.of<ThemeProvider>(context, listen: false)
              .applyFromData(profileData);
          Provider.of<LocaleProvider>(context, listen: false)
              .applyFromData(profileData);
        }
      } catch (e) {
        debugPrint('SplashScreen._navigateBasedOnAuth: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const WelcomePage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/images/new_logo-removebg-removenm.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            // const SizedBox(height: AppTheme.spacingS),

            // Tagline
            FadeTransition(
              opacity: _animation,
              child: Text(
                AppLocalizations.of(context)!.splashText,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
