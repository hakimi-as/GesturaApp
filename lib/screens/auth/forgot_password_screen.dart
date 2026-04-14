import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glass_ui.dart';
import '../../widgets/common/aurora_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      setState(() => _emailSent = true);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Icon
          Center(
            child: GlassCard(
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
              child: const SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(),

          const SizedBox(height: 30),

          // Title
          Center(
            child: Text(
              l10n.forgotPassword,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          Center(
            child: Text(
              l10n.forgotPasswordSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textMuted,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),

          // Email Field
          GlassTextField(
            controller: _emailController,
            hint: l10n.enterEmail,
            label: l10n.email,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseEnterEmail;
              }
              if (!value.contains('@')) {
                return l10n.pleaseEnterValidEmail;
              }
              return null;
            },
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

          const SizedBox(height: 30),

          // Reset Button
          GlassPrimaryButton(
            label: l10n.sendResetLink,
            onPressed: _handleResetPassword,
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.backToSignIn,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Success Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.success,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(),

        const SizedBox(height: 30),

        Text(
          l10n.emailSent,
          style: Theme.of(context).textTheme.headlineLarge,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${l10n.emailSentDesc}\n${_emailController.text}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 40),

        GlassPrimaryButton(
          label: l10n.backToSignIn,
          onPressed: () => Navigator.pop(context),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 20),

        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            l10n.didntReceive,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
