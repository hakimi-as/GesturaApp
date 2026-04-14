import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../widgets/common/glass_ui.dart';
import '../../widgets/common/aurora_scaffold.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedUserType = AppConstants.userTypeLearner;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      userType: _selectedUserType,
    );

    if (success && mounted) {
      await AnalyticsService.logSignUp(method: 'email');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      AppLocalizations.of(context).createAccount,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 8),

                    Text(
                      AppLocalizations.of(context).joinCommunity,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textMuted,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 40),

                    // Full Name Field
                    GlassTextField(
                      controller: _nameController,
                      hint: AppLocalizations.of(context).enterFullName,
                      label: AppLocalizations.of(context).fullName,
                      prefixIcon: Icons.person_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context).pleaseEnterName;
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                    const SizedBox(height: 20),

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
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                    const SizedBox(height: 20),

                    // User Type Selection
                    Text(
                      AppLocalizations.of(context).iAmA.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildUserTypeChip('Learner', AppConstants.userTypeLearner, Icons.menu_book_rounded),
                        const SizedBox(width: 12),
                        _buildUserTypeChip('Deaf/HoH', AppConstants.userTypeDeaf, Icons.sign_language),
                        const SizedBox(width: 12),
                        _buildUserTypeChip('Educator', AppConstants.userTypeEducator, Icons.school_rounded),
                      ],
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 20),

                    // Password Field
                    GlassTextField(
                      controller: _passwordController,
                      hint: AppLocalizations.of(context).createPassword,
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
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    GlassTextField(
                      controller: _confirmPasswordController,
                      hint: AppLocalizations.of(context).confirmPasswordHint,
                      label: AppLocalizations.of(context).confirmPassword,
                      prefixIcon: Icons.lock_outlined,
                      obscureText: _obscureConfirmPassword,
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: context.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        final l10n = AppLocalizations.of(context);
                        if (value == null || value.isEmpty) return l10n.pleaseConfirmPassword;
                        if (value != _passwordController.text) return l10n.passwordsDoNotMatch;
                        return null;
                      },
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),

                    const SizedBox(height: 40),

                    // Register Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return GlassPrimaryButton(
                          label: AppLocalizations.of(context).createAccount,
                          onPressed: authProvider.status == AuthStatus.loading
                              ? null
                              : _handleRegister,
                          loading: authProvider.status == AuthStatus.loading,
                        );
                      },
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${AppLocalizations.of(context).alreadyHaveAccount.split('?').first}? ',
                          style: TextStyle(color: context.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            AppLocalizations.of(context).signIn,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedUserType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedUserType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.10),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : context.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
