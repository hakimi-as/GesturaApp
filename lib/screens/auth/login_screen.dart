import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../widgets/common/glass_ui.dart';
import '../../widgets/common/aurora_scaffold.dart';
import '../main_navigator.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      await AnalyticsService.logLogin(method: 'email');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigator()),
        );
      }
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AuroraScaffold(child: SizedBox.expand()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo & Title
                    Center(
                      child: Column(
                        children: [
                          GlassCard(
                            gradient: AppColors.primaryGradient,
                            padding: EdgeInsets.zero,
                            decorationOverride: context.glassCardDecoration().copyWith(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: const Center(
                                child: Icon(
                                  Icons.sign_language,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).scale(),

                          const SizedBox(height: 20),

                          Text(
                            AppLocalizations.of(context).welcomeBack,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 8),

                          Text(
                            AppLocalizations.of(context).loginSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.textMuted,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Email Field
                    GlassTextField(
                      controller: _emailController,
                      hint: AppLocalizations.of(context).enterEmail,
                      label: AppLocalizations.of(context).email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final l10n = AppLocalizations.of(context);
                        if (value == null || value.isEmpty) return l10n.pleaseEnterEmail;
                        if (!value.contains('@')) return l10n.pleaseEnterValidEmail;
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                    const SizedBox(height: 20),

                    // Password Field
                    GlassTextField(
                      controller: _passwordController,
                      hint: AppLocalizations.of(context).enterPassword,
                      label: AppLocalizations.of(context).password,
                      prefixIcon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: context.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        final l10n = AppLocalizations.of(context);
                        if (value == null || value.isEmpty) return l10n.pleaseEnterPassword;
                        if (value.length < 6) return l10n.passwordMinLength;
                        return null;
                      },
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),

                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: Text(
                          AppLocalizations.of(context).forgotPassword,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 30),

                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return GlassPrimaryButton(
                          label: AppLocalizations.of(context).signIn,
                          onPressed: authProvider.status == AuthStatus.loading
                              ? null
                              : _handleLogin,
                          loading: authProvider.status == AuthStatus.loading,
                        );
                      },
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

                    const SizedBox(height: 30),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).dontHaveAccount.split('?').first + '? ',
                          style: TextStyle(color: context.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(
                            AppLocalizations.of(context).signUp,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
