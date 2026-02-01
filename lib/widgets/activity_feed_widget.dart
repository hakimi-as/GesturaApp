import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/theme.dart';
import '../services/haptic_service.dart';
import '../services/friend_service.dart';
import '../models/friend_model.dart';
import '../screens/social/friend_profile_screen.dart';

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('📢', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Friend Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadActivities,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: context.textMuted,
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
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your friends\' activities will appear here',
              style: TextStyle(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: activity.userPhotoUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
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
                          color: context.bgElevated,
                          child: Center(
                            child: Text(
                              activity.userInitials,
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        activity.timeAgo,
                        style: TextStyle(
                          color: context.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        activity.activityIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.title ?? activity.description,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (activity.xpEarned > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '+${activity.xpEarned} XP',
                            style: TextStyle(
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
            ),
          ],
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