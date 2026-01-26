import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/haptic_service.dart';

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
      emoji: '📡',
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }

  /// Server error preset
  factory ErrorStateWidget.server({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      emoji: '🔧',
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }

  /// Generic error preset
  factory ErrorStateWidget.generic({String? message, VoidCallback? onRetry}) {
    return ErrorStateWidget(
      emoji: '😕',
      title: 'Oops!',
      message: message ?? 'Something went wrong. Please try again.',
      onRetry: onRetry,
    );
  }

  /// Timeout error preset
  factory ErrorStateWidget.timeout({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      emoji: '⏱️',
      title: 'Request Timeout',
      message: 'The request took too long. Please try again.',
      onRetry: onRetry,
    );
  }

  /// Permission denied preset
  factory ErrorStateWidget.permission({VoidCallback? onRetry}) {
    return ErrorStateWidget(
      emoji: '🔒',
      title: 'Permission Denied',
      message: 'You don\'t have permission to access this content.',
      onRetry: onRetry,
      showRetry: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or emoji
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 64))
            else if (icon != null)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.error).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? AppColors.error,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Title
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 8),
            
            // Message
            if (message != null)
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 24),
            
            // Retry button
            if (showRetry && onRetry != null)
              ElevatedButton.icon(
                onPressed: () {
                  HapticService.buttonTap();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
      emoji: '📚',
      title: 'No Lessons Yet',
      message: 'Lessons will appear here once they\'re added.',
      actionText: 'Refresh',
      onAction: onRefresh,
    );
  }

  /// No categories preset
  factory EmptyStateWidget.noCategories({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      emoji: '📂',
      title: 'No Categories',
      message: 'Categories will appear here.',
      actionText: 'Refresh',
      onAction: onRefresh,
    );
  }

  /// No progress preset
  factory EmptyStateWidget.noProgress({VoidCallback? onStart}) {
    return EmptyStateWidget(
      emoji: '🚀',
      title: 'Start Learning!',
      message: 'Complete lessons to track your progress here.',
      actionText: 'Start Learning',
      onAction: onStart,
    );
  }

  /// No badges preset
  factory EmptyStateWidget.noBadges({VoidCallback? onLearn}) {
    return EmptyStateWidget(
      emoji: '🏆',
      title: 'No Badges Yet',
      message: 'Complete lessons and challenges to earn badges!',
      actionText: 'Start Earning',
      onAction: onLearn,
    );
  }

  /// No notifications preset
  factory EmptyStateWidget.noNotifications() {
    return const EmptyStateWidget(
      emoji: '🔔',
      title: 'All Caught Up!',
      message: 'You have no new notifications.',
    );
  }

  /// No search results preset
  factory EmptyStateWidget.noSearchResults({String? query}) {
    return EmptyStateWidget(
      emoji: '🔍',
      title: 'No Results Found',
      message: query != null 
          ? 'No results for "$query". Try a different search.'
          : 'Try searching for something else.',
    );
  }

  /// No friends preset
  factory EmptyStateWidget.noFriends({VoidCallback? onAddFriends}) {
    return EmptyStateWidget(
      emoji: '👥',
      title: 'No Friends Yet',
      message: 'Add friends to compete on the leaderboard!',
      actionText: 'Add Friends',
      onAction: onAddFriends,
    );
  }

  /// No challenges preset
  factory EmptyStateWidget.noChallenges() {
    return const EmptyStateWidget(
      emoji: '🎯',
      title: 'No Challenges',
      message: 'New challenges will appear here daily.',
    );
  }

  /// No quizzes preset
  factory EmptyStateWidget.noQuizzes({VoidCallback? onLearn}) {
    return EmptyStateWidget(
      emoji: '❓',
      title: 'Learn First!',
      message: 'Complete some lessons before taking quizzes.',
      actionText: 'Start Learning',
      onAction: onLearn,
    );
  }

  /// Offline mode preset
  factory EmptyStateWidget.offline({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      emoji: '📴',
      title: 'You\'re Offline',
      message: 'Connect to the internet to see this content.',
      actionText: 'Retry',
      onAction: onRetry,
    );
  }

  /// Coming soon preset
  factory EmptyStateWidget.comingSoon() {
    return const EmptyStateWidget(
      emoji: '🚧',
      title: 'Coming Soon!',
      message: 'This feature is under development.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or emoji
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 64))
            else if (icon != null)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Title
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 8),
            
            // Message
            if (message != null)
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 24),
            
            // Custom action widget or default button
            if (action != null)
              action!
            else if (onAction != null && actionText != null)
              ElevatedButton.icon(
                onPressed: () {
                  HapticService.buttonTap();
                  onAction!();
                },
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textMuted,
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
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
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
                child: Icon(Icons.refresh, color: AppColors.error, size: 18),
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
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
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
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
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
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
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
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
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
            Icon(Icons.cloud_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('You\'re offline. Some features may be limited.')),
          ],
        ),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}