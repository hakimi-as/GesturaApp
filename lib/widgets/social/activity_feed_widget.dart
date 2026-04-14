import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../services/haptic_service.dart';
import '../../services/friend_service.dart';
import '../../models/friend_model.dart';
import '../../screens/social/friend_profile_screen.dart';
import '../common/glass_ui.dart';

class ActivityFeedWidget extends StatefulWidget {
  final String userId;
  final bool showHeader;
  final int limit;

  const ActivityFeedWidget({
    super.key,
    required this.userId,
    this.showHeader = true,
    this.limit = 20,
  });

  @override
  State<ActivityFeedWidget> createState() => _ActivityFeedWidgetState();
}

class _ActivityFeedWidgetState extends State<ActivityFeedWidget> {
  List<FriendActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);

    try {
      final activities = await FriendService.getFriendActivities(widget.userId);
      if (mounted) {
        setState(() {
          _activities = activities.take(widget.limit).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_activities.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                // Small teal icon box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: kGlassRadius,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Friend Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorsDark.textPrimary,
                      ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadActivities,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppColors.glassCard(),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColorsDark.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            return _buildActivityCard(_activities[index])
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 50))
                .slideX(begin: -0.1);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassEmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'No activity yet',
      subtitle: 'Your friends\' activities will appear here',
    );
  }

  Widget _buildActivityCard(FriendActivity activity) {
    return GestureDetector(
      onTap: () {
        HapticService.buttonTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendProfileScreen(friendId: activity.userId),
          ),
        );
      },
      child: GlassTile(
        padding: const EdgeInsets.all(16),
        leading: _buildAvatar(activity),
        title: Row(
          children: [
            Expanded(
              child: Text(
                activity.userName,
                style: const TextStyle(
                  color: AppColorsDark.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Timestamp — muted, 11px
            Text(
              activity.timeAgo,
              style: const TextStyle(
                color: AppColorsDark.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                // Small teal activity icon
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.title ?? activity.description,
                    style: const TextStyle(
                      color: AppColorsDark.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (activity.xpEarned > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.primary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '+${activity.xpEarned} XP',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          HapticService.buttonTap();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendProfileScreen(friendId: activity.userId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(FriendActivity activity) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: activity.userPhotoUrl == null
            ? const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: activity.userPhotoUrl != null
            ? CachedNetworkImage(
                imageUrl: activity.userPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF0D1A1A),
                  child: Center(
                    child: Text(
                      activity.userInitials,
                      style: const TextStyle(
                        color: AppColorsDark.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  activity.userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Compact activity feed for dashboard
class CompactActivityFeed extends StatelessWidget {
  final String userId;
  final int limit;

  const CompactActivityFeed({
    super.key,
    required this.userId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ActivityFeedWidget(
      userId: userId,
      showHeader: false,
      limit: limit,
    );
  }
}
