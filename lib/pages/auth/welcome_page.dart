// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/pages/auth/login_page.dart';
import 'package:spendwise/pages/auth/register_page.dart';
import 'package:spendwise/pages/home_page.dart';
import 'package:spendwise/providers/locale_provider.dart';
import 'package:spendwise/providers/profile_provider.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithGoogle();
      await SupabaseDataService().init();
      if (!mounted) return;
      final profileData = await AuthService().getProfile();
      Provider.of<ProfileProvider>(context, listen: false)
          .applyFromData(profileData);
      Provider.of<ThemeProvider>(context, listen: false)
          .applyFromData(profileData);
      Provider.of<LocaleProvider>(context, listen: false)
          .applyFromData(profileData);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    final bg = isDark ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);
    final bgGradientEnd = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D29);
    final subtextColor =
        isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);
    final btnBg = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final btnFg = isDark ? AppTheme.darkBgColor : Colors.white;
    final borderColor =
        isDark ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.08);
    final socialBg = isDark ? AppTheme.darkCardColor : Colors.white;
    final linkColor = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final glowColor1 = AppTheme.primaryColor.withOpacity(isDark ? 0.3 : 0.12);
    final glowColor2 = const Color(0xFF7B2FFF).withOpacity(isDark ? 0.1 : 0.05);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bg, bgGradientEnd],
          ),
        ),
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.3,
              child: Container(
                width: size.width * 1.2,
                height: size.height * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [glowColor1, glowColor2, Colors.transparent],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Image.asset(
                        'assets/images/new_logo-removebg.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Main text
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.authWelcomeTitle,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.authWelcomeSubtitle,
                              style: TextStyle(
                                fontSize: 15,
                                color: subtextColor,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Buttons
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            // Sign In button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginPage()),
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: btnBg,
                                  foregroundColor: btnFg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  l10n.authSignIn,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Google button — full width
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isLoading ? null : _handleGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: socialBg,
                                  foregroundColor: textColor,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: textColor,
                                        ),
                                      )
                                    : Image(
                                        image: const AssetImage(
                                            'assets/images/logo_google.png'),
                                        width: 22,
                                        height: 22,
                                      ),
                                label: Text(
                                  'Google',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.authNoAccount,
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterPage()),
                                          ),
                                  child: Text(
                                    l10n.authSignUp,
                                    style: TextStyle(
                                      color: linkColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
