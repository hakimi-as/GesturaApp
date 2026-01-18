import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

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
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(),

          const SizedBox(height: 30),

          // Title
          Center(
            child: Text(
              'Forgot Password?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'No worries! Enter your email and we\'ll send you a reset link.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textMuted,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),

          // Email Field
          Text(
            'Email',
            style: Theme.of(context).textTheme.labelLarge,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined, color: context.textMuted),
              filled: true,
              fillColor: context.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),

          const SizedBox(height: 30),

          // Reset Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back to Sign In',
                style: TextStyle(
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Success Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: AppColors.success,
          ),
        ).animate().fadeIn(duration: 500.ms).scale(),

        const SizedBox(height: 30),

        Text(
          'Email Sent!',
          style: Theme.of(context).textTheme.headlineLarge,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'We\'ve sent a password reset link to\n${_emailController.text}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.textMuted,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 20),

        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            'Didn\'t receive? Try again',
            style: TextStyle(
              color: context.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}