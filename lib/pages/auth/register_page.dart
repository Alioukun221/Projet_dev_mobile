import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/pages/auth/login_page.dart';
import 'package:spendwise/pages/home_page.dart';
import 'package:spendwise/providers/theme_provider.dart';
import 'package:spendwise/services/auth_service.dart';
import 'package:spendwise/services/supabase_data_service.dart';
import 'package:spendwise/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_agreeTerms) {
      _showError(l10n.authAgreeTermsRequired);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService().signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (!mounted) return;

      // If Supabase requires email confirmation
      if (response.user != null && response.session == null) {
        _showSuccess(AppLocalizations.of(context)!.authAccountCreated);
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        });
        return;
      }

      // Auto-logged in after signup - init data service
      await SupabaseDataService().init();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentColor,
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
    final linkColor = isDark ? AppTheme.accentColor : AppTheme.primaryColor;
    final backBtnBg = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);
    final backBtnIcon = isDark ? Colors.white : AppTheme.textPrimaryColor;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final dividerTextColor = isDark
        ? Colors.white.withOpacity(0.3)
        : AppTheme.textSecondaryColor;
    final socialBorder = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);
    final socialBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.03);
    final socialTextColor = isDark ? Colors.white : AppTheme.textPrimaryColor;
    final glowColor1 = const Color(0xFF7B2FFF).withOpacity(isDark ? 0.2 : 0.08);
    final glowColor2 = const Color(0xFF005EFF).withOpacity(isDark ? 0.08 : 0.04);
    final checkboxBorder = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.15);

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
                    colors: [glowColor1, glowColor2, Colors.transparent],
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
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        l10n.authCreateAccount,
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
                        l10n.authCreateAccountSubtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: subtextColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _AuthTextField(
                              controller: _nameController,
                              hintText: l10n.authFullNameHint,
                              icon: Icons.person_outline_rounded,
                              fillColor: inputFillColor,
                              borderColor: inputBorderColor,
                              hintColor: inputHintColor,
                              iconColor: inputIconColor,
                              textColor: inputTextColor,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.authNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AuthTextField(
                              controller: _emailController,
                              hintText: l10n.authEmailHint,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              fillColor: inputFillColor,
                              borderColor: inputBorderColor,
                              hintColor: inputHintColor,
                              iconColor: inputIconColor,
                              textColor: inputTextColor,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.authEmailRequired;
                                }
                                if (!value.contains('@')) {
                                  return l10n.authEmailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AuthTextField(
                              controller: _passwordController,
                              hintText: l10n.authPasswordHint,
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              fillColor: inputFillColor,
                              borderColor: inputBorderColor,
                              hintColor: inputHintColor,
                              iconColor: inputIconColor,
                              textColor: inputTextColor,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: inputIconColor,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.authPasswordEnter;
                                }
                                if (value.length < 6) {
                                  return l10n.authPasswordTooShort;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AuthTextField(
                              controller: _confirmPasswordController,
                              hintText: l10n.authConfirmPasswordHint,
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirm,
                              fillColor: inputFillColor,
                              borderColor: inputBorderColor,
                              hintColor: inputHintColor,
                              iconColor: inputIconColor,
                              textColor: inputTextColor,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: inputIconColor,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.authConfirmPasswordRequired;
                                }
                                if (value != _passwordController.text) {
                                  return l10n.authPasswordMismatch;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Terms checkbox
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _agreeTerms = !_agreeTerms),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _agreeTerms
                                      ? linkColor
                                      : checkboxBorder,
                                  width: 1.5,
                                ),
                                color: _agreeTerms
                                    ? linkColor
                                    : Colors.transparent,
                              ),
                              child: _agreeTerms
                                  ? Icon(Icons.check,
                                      size: 14, color: btnFg)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: l10n.authAgreeTerms,
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.authTermsConditions,
                                    style: TextStyle(
                                      color: linkColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Sign up button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  l10n.authCreateAccountBtn,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.authOrSignUpWith,
                              style: TextStyle(
                                color: dividerTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: dividerColor)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Social buttons
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

                      const SizedBox(height: 28),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.authHaveAccount,
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.authSignIn,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color fillColor;
  final Color borderColor;
  final Color hintColor;
  final Color iconColor;
  final Color textColor;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    required this.fillColor,
    required this.borderColor,
    required this.hintColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: 15),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
