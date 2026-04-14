import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/haptic_service.dart';
import 'glass_ui.dart';

// ==================== ERROR WIDGET ====================

/// Reusable error widget with retry functionality
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final String? emoji;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryText;
  final bool showRetry;
  final Color? iconColor;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.emoji,
    this.icon,
    this.onRetry,
    this.retryText = 'Try Again',
    this.showRetry = true,
    this.iconColor,
  });

  /// Network error preset
  factory ErrorStateWidget.network({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      icon: Icons.wifi_off_rounded,
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }

  /// Server error preset
  factory ErrorStateWidget.server({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      icon: Icons.build_rounded,
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }

  /// Generic error preset
  factory ErrorStateWidget.generic({String? message, VoidCallback? onRetry}) {
    return ErrorStateWidget(
      icon: Icons.sentiment_dissatisfied_rounded,
      title: 'Oops!',
      message: message ?? 'Something went wrong. Please try again.',
      onRetry: onRetry,
    );
  }

  /// Timeout error preset
  factory ErrorStateWidget.timeout({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      icon: Icons.timer_off_rounded,
      title: 'Request Timeout',
      message: 'The request took too long. Please try again.',
      onRetry: onRetry,
    );
  }

  /// Permission denied preset
  factory ErrorStateWidget.permission({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      icon: Icons.lock_rounded,
      title: 'Permission Denied',
      message: 'You don\'t have permission to access this content.',
      onRetry: onRetry,
      showRetry: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = iconColor ?? AppColors.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glass card wrapping icon — error red border
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppColors.glassCard().copyWith(
                border: Border.all(
                  color: AppColors.error.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 48,
                color: errorColor,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  color: AppColorsDark.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 8),

            // Message
            if (message != null)
              Text(
                message!,
                style: const TextStyle(
                  color: AppColorsDark.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 24),

            // Retry button
            if (showRetry && onRetry != null)
              GlassPrimaryButton(
                label: retryText,
                onPressed: () {
                  HapticService.buttonTap();
                  onRetry!();
                },
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}


// ==================== EMPTY STATE WIDGET ====================

/// Reusable empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final String? emoji;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onAction;
  final String? actionText;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    this.title,
    this.message,
    this.emoji,
    this.icon,
    this.action,
    this.onAction,
    this.actionText,
    this.iconColor,
  });

  /// No lessons preset
  factory EmptyStateWidget.noLessons({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.menu_book_rounded,
      title: 'No Lessons Yet',
      message: 'Lessons will appear here once they\'re added.',
      actionText: 'Refresh',
      onAction: onRefresh,
    );
  }

  /// No categories preset
  factory EmptyStateWidget.noCategories({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.folder_open_rounded,
      title: 'No Categories',
      message: 'Categories will appear here.',
      actionText: 'Refresh',
      onAction: onRefresh,
    );
  }

  /// No progress preset
  factory EmptyStateWidget.noProgress({VoidCallback? onStart}) {
    return EmptyStateWidget(
      icon: Icons.rocket_launch_rounded,
      title: 'Start Learning!',
      message: 'Complete lessons to track your progress here.',
      actionText: 'Start Learning',
      onAction: onStart,
    );
  }

  /// No badges preset
  factory EmptyStateWidget.noBadges({VoidCallback? onLearn}) {
    return EmptyStateWidget(
      icon: Icons.emoji_events_rounded,
      title: 'No Badges Yet',
      message: 'Complete lessons and challenges to earn badges!',
      actionText: 'Start Earning',
      onAction: onLearn,
    );
  }

  /// No notifications preset
  factory EmptyStateWidget.noNotifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_rounded,
      title: 'All Caught Up!',
      message: 'You have no new notifications.',
    );
  }

  /// No search results preset
  factory EmptyStateWidget.noSearchResults({String? query}) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      message: query != null
          ? 'No results for "$query". Try a different search.'
          : 'Try searching for something else.',
    );
  }

  /// No friends preset
  factory EmptyStateWidget.noFriends({VoidCallback? onAddFriends}) {
    return EmptyStateWidget(
      icon: Icons.group_rounded,
      title: 'No Friends Yet',
      message: 'Add friends to compete on the leaderboard!',
      actionText: 'Add Friends',
      onAction: onAddFriends,
    );
  }

  /// No challenges preset
  factory EmptyStateWidget.noChallenges() {
    return const EmptyStateWidget(
      icon: Icons.military_tech_rounded,
      title: 'No Challenges',
      message: 'New challenges will appear here daily.',
    );
  }

  /// No quizzes preset
  factory EmptyStateWidget.noQuizzes({VoidCallback? onLearn}) {
    return EmptyStateWidget(
      icon: Icons.quiz_rounded,
      title: 'Learn First!',
      message: 'Complete some lessons before taking quizzes.',
      actionText: 'Start Learning',
      onAction: onLearn,
    );
  }

  /// Offline mode preset
  factory EmptyStateWidget.offline({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'You\'re Offline',
      message: 'Connect to the internet to see this content.',
      actionText: 'Retry',
      onAction: onRetry,
    );
  }

  /// Coming soon preset
  factory EmptyStateWidget.comingSoon() {
    return const EmptyStateWidget(
      icon: Icons.construction_rounded,
      title: 'Coming Soon!',
      message: 'This feature is under development.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prefer icon over emoji; fall back to a generic icon
    final resolvedIcon = icon ?? Icons.info_outline_rounded;

    return GlassEmptyState(
      icon: resolvedIcon,
      title: title ?? '',
      subtitle: message,
      actionLabel: (onAction != null && actionText != null) ? actionText : null,
      onAction: onAction != null && actionText != null
          ? () {
              HapticService.buttonTap();
              onAction!();
            }
          : null,
    ).animate().fadeIn(duration: 300.ms);
  }
}


// ==================== LOADING STATE WIDGET ====================

/// Reusable loading widget with optional message
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.color,
    this.size = 40,
  });

  /// Default loading
  factory LoadingStateWidget.standard({String? message}) {
    return LoadingStateWidget(message: message);
  }

  /// Small inline loading
  factory LoadingStateWidget.small() {
    return const LoadingStateWidget(size: 24);
  }

  /// Loading with custom message
  factory LoadingStateWidget.withMessage(String message) {
    return LoadingStateWidget(message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primary,
              strokeWidth: size > 30 ? 4 : 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColorsDark.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}


// ==================== INLINE ERROR WIDGET ====================

/// Small inline error for form fields, cards, etc.
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showIcon;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppColors.glassCard().copyWith(
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: () {
                HapticService.buttonTap();
                onRetry!();
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.refresh_rounded, color: AppColors.error, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}


// ==================== SNACKBAR HELPERS ====================

/// Helper class for showing consistent snackbars
class AppSnackBar {
  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    HapticService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    HapticService.error();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show warning snackbar
  static void showWarning(BuildContext context, String message) {
    HapticService.warning();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show offline snackbar
  static void showOffline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('You\'re offline. Some features may be limited.')),
          ],
        ),
        backgroundColor: Color(0xFF374151),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
