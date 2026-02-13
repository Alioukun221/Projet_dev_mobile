import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/pages/auth/login_page.dart';
import 'package:spendwise/pages/auth/register_page.dart';
import 'package:spendwise/providers/theme_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    final bgGradient = isDark
        ? const [Color(0xFF0B0E2D), Color(0xFF0A0A1A)]
        : const [Color(0xFFFFFFFF), Color(0xFFF0F2F8)];
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryColor;
    final subtextColor =
        isDark ? Colors.white.withOpacity(0.5) : AppTheme.textSecondaryColor;
    final btnBg = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final btnFg = isDark ? const Color(0xFF0A0A1A) : Colors.white;
    final socialBorder =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);
    final socialBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);
    final socialTextColor = isDark ? Colors.white : AppTheme.textPrimaryColor;
    final linkColor = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final glowColor1 = const Color(0xFF005EFF).withOpacity(isDark ? 0.3 : 0.12);
    final glowColor2 = const Color(0xFF7B2FFF).withOpacity(isDark ? 0.1 : 0.05);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: Stack(
          children: [
            // Background glow effect
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

            // Content
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
                        'assets/images/logo_2-removebg.png',
                        width: 100,
                        height: 100,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
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
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                },
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

                            // Social buttons row
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'Google',
                                    borderColor: socialBorder,
                                    bgColor: socialBg,
                                    textColor: socialTextColor,
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    icon: Icons.apple_rounded,
                                    label: 'Apple',
                                    borderColor: socialBorder,
                                    bgColor: socialBg,
                                    textColor: socialTextColor,
                                    onTap: () {},
                                  ),
                                ),
                              ],
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color borderColor;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          color: bgColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
