import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().resetPassword(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.authUnexpectedError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    final subtextColor = isDark
        ? Colors.white.withOpacity(0.45)
        : AppTheme.textSecondaryColor;
    final btnBg = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final btnFg = isDark ? const Color(0xFF0A0A1A) : Colors.white;
    final backBtnBg = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);
    final backBtnIcon = isDark ? Colors.white : AppTheme.textPrimaryColor;
    final glowColor1 = const Color(0xFF005EFF).withOpacity(isDark ? 0.2 : 0.08);
    final iconBoxBg = isDark
        ? AppTheme.primaryColor.withOpacity(0.15)
        : AppTheme.primaryColor.withOpacity(0.08);
    final successBg = isDark
        ? AppTheme.accentColor.withOpacity(0.1)
        : AppTheme.accentColor.withOpacity(0.06);
    final successBorder = isDark
        ? AppTheme.accentColor.withOpacity(0.2)
        : AppTheme.accentColor.withOpacity(0.15);
    final emailDisplayColor = isDark
        ? Colors.white.withOpacity(0.6)
        : AppTheme.textSecondaryColor;

    // Input field colors
    final inputFillColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.03);
    final inputBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final inputHintColor = isDark
        ? Colors.white.withOpacity(0.25)
        : AppTheme.textSecondaryColor.withOpacity(0.6);
    final inputIconColor = isDark
        ? Colors.white.withOpacity(0.3)
        : AppTheme.textSecondaryColor;
    final inputTextColor = isDark ? Colors.white : AppTheme.textPrimaryColor;

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
            // Background glow
            Positioned(
              top: -size.height * 0.05,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [glowColor1, Colors.transparent],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: backBtnBg,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: backBtnIcon,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: iconBoxBg,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        l10n.authResetPassword,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _emailSent
                            ? l10n.authResetEmailSentSubtitle
                            : l10n.authResetSubtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: subtextColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      if (_emailSent) ...[
                        // Success state
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: successBg,
                            border: Border.all(color: successBorder),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.mark_email_read_rounded,
                                color: AppTheme.accentColor,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.authEmailSent,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _emailController.text.trim(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: emailDisplayColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBg,
                              foregroundColor: btnFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.authBackToSignIn,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Form
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: inputTextColor, fontSize: 15),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.authEmailRequired;
                              }
                              if (!value.contains('@')) {
                                return l10n.authEmailInvalid;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: l10n.authEmailHint,
                              hintStyle: TextStyle(
                                color: inputHintColor,
                                fontSize: 15,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: inputIconColor,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: inputFillColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryColor, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: AppTheme.errorColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBg,
                              foregroundColor: btnFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: btnFg,
                                    ),
                                  )
                                : Text(
                                    l10n.authSendResetLink,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
