import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_model.dart';
import '../models/badge_model.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // Share basic text stats
  Future<void> shareTextStats(UserModel user) async {
    final text = '''
🤟 My Gestura Progress 🤟

🔥 ${user.currentStreak} Day Streak
⭐ ${user.totalXP} XP Earned
🤟 ${user.signsLearned} Signs Learned
🎯 Level ${user.level}
🏆 ${user.totalBadges} Badges Unlocked

Learning sign language with Gestura! 📱
Download: https://gestura.app
''';

    await Share.share(text, subject: 'My Gestura Progress');
  }

  // Share achievement
  Future<void> shareAchievement(BadgeModel badge) async {
    final text = '''
🏆 Achievement Unlocked! 🏆

${badge.icon} ${badge.name}
"${badge.description}"

${_getTierEmoji(badge.tier)} ${badge.tier.name.toUpperCase()} Badge
+${badge.xpReward} XP

Learning sign language with Gestura! 📱
''';

    await Share.share(text, subject: 'I unlocked a badge on Gestura!');
  }

  // Share streak milestone
  Future<void> shareStreakMilestone(int streakDays) async {
    String milestone;
    if (streakDays >= 365) {
      milestone = '🎉 ONE YEAR STREAK! 🎉';
    } else if (streakDays >= 100) {
      milestone = '🎉 100 DAY STREAK! 🎉';
    } else if (streakDays >= 30) {
      milestone = '🔥 30 DAY STREAK! 🔥';
    } else if (streakDays >= 7) {
      milestone = '🔥 WEEK STREAK! 🔥';
    } else {
      milestone = '🔥 $streakDays Day Streak! 🔥';
    }

    final text = '''
$milestone

I've been learning sign language for $streakDays days straight on Gestura!

Join me: https://gestura.app
''';

    await Share.share(text, subject: 'My learning streak on Gestura!');
  }

  // Share level up
  Future<void> shareLevelUp(int level) async {
    final text = '''
🎉 LEVEL UP! 🎉

I just reached Level $level on Gestura!

Learning sign language one sign at a time 🤟

Download: https://gestura.app
''';

    await Share.share(text, subject: 'I leveled up on Gestura!');
  }

  // Share challenge completion
  Future<void> shareChallengeCompletion(String challengeName, int xpReward) async {
    final text = '''
🎯 Challenge Completed! 🎯

"$challengeName"
+$xpReward XP earned!

Learning sign language with Gestura! 📱
''';

    await Share.share(text, subject: 'I completed a challenge on Gestura!');
  }

  // Share quiz score
  Future<void> shareQuizScore(String quizName, int score, int total) async {
    final percentage = ((score / total) * 100).toInt();
    final emoji = percentage == 100
        ? '💯'
        : percentage >= 80
            ? '🌟'
            : percentage >= 60
                ? '👍'
                : '📚';

    final text = '''
$emoji Quiz Results! $emoji

"$quizName"
Score: $score/$total ($percentage%)

${percentage == 100 ? 'Perfect score!' : percentage >= 80 ? 'Great job!' : 'Keep practicing!'}

Learning sign language with Gestura! 📱
''';

    await Share.share(text, subject: 'My Gestura quiz results!');
  }

  // Share leaderboard rank
  Future<void> shareLeaderboardRank(int rank, int totalXP) async {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '🏆';

    final text = '''
$medal Leaderboard Rank: #$rank $medal

⭐ Total XP: $totalXP

Can you beat my score? 

Download Gestura: https://gestura.app
''';

    await Share.share(text, subject: 'My Gestura Leaderboard Rank!');
  }

  // Capture widget as image and share
  Future<void> shareWidgetAsImage(
    GlobalKey key, {
    required String shareText,
    String? subject,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gestura_share.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: subject,
      );
    } catch (e) {
      debugPrint('Error sharing widget as image: $e');
      // Fallback to text share
      await Share.share(shareText, subject: subject);
    }
  }

  String _getTierEmoji(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return '🥉';
      case BadgeTier.silver:
        return '🥈';
      case BadgeTier.gold:
        return '🥇';
      case BadgeTier.platinum:
        return '💎';
    }
  }
}