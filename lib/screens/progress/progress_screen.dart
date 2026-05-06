import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/design_system.dart';
import '../../config/theme.dart';
import '../../models/progress_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _filter = 'all'; // 'all' | 'lessons' | 'quizzes'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId != null) {
        Provider.of<ProgressProvider>(context, listen: false)
            .loadUserProgress(auth.userId!);
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    if (diff < 30) return 'This month';
    return 'Earlier';
  }

  List<LearningProgressModel> _filtered(List<LearningProgressModel> all) {
    List<LearningProgressModel> list;
    if (_filter == 'lessons') {
      list = all.where((p) => !p.isQuiz).toList();
    } else if (_filter == 'quizzes') {
      list = all.where((p) => p.isQuiz).toList();
    } else {
      list = List.from(all);
    }
    list.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    return list;
  }

  Map<String, List<LearningProgressModel>> _group(
      List<LearningProgressModel> items) {
    final Map<String, List<LearningProgressModel>> grouped = {};
    const order = ['Today', 'Yesterday', 'This week', 'This month', 'Earlier'];
    for (final item in items) {
      final label = _groupLabel(item.lastAccessedAt);
      grouped.putIfAbsent(label, () => []).add(item);
    }
    // Preserve chronological group order
    return Map.fromEntries(
      order
          .where(grouped.containsKey)
          .map((k) => MapEntry(k, grouped[k]!)),
    );
  }

  // ── Real stats from progress list ─────────────────────────────────────────

  int _totalLessons(List<LearningProgressModel> list) =>
      list.where((p) => !p.isQuiz && p.isCompleted).length;

  int _totalQuizzes(List<LearningProgressModel> list) =>
      list.where((p) => p.isQuiz && p.isCompleted).length;

  int _totalXpEarned(List<LearningProgressModel> list) =>
      list.fold(0, (sum, p) => sum + p.xpEarned);

  double _bestAccuracy(List<LearningProgressModel> list) {
    final quizzes = list.where((p) => p.isQuiz && p.bestAccuracy > 0).toList();
    if (quizzes.isEmpty) return 0;
    return quizzes.map((p) => p.bestAccuracy).reduce((a, b) => a > b ? a : b);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Consumer2<AuthProvider, ProgressProvider>(
          builder: (context, auth, progressProvider, _) {
            final all = progressProvider.progressList;
            final filtered = _filtered(all);
            final grouped = _group(filtered);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        TapScale(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Icon(Icons.arrow_back,
                                color: context.textSecondary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Activity',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: context.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: context.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Text(
                            '${all.length} entries',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // ── Stat strip ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildStatStrip(context, all)
                      .animate()
                      .fadeIn(delay: 80.ms)
                      .slideY(begin: 0.06),
                ),

                // ── Filter chips ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Row(
                      children: [
                        _chip('All', 'all'),
                        const SizedBox(width: 8),
                        _chip('Lessons', 'lessons'),
                        const SizedBox(width: 8),
                        _chip('Quizzes', 'quizzes'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 140.ms),
                ),

                // ── Empty state ──────────────────────────────────────────
                if (progressProvider.isLoading)
                  SliverToBoxAdapter(child: _buildLoading(context))
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty(context))

                // ── Grouped list ─────────────────────────────────────────
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, sectionIdx) {
                        final group =
                            grouped.entries.elementAt(sectionIdx);
                        return _buildSection(
                            context, group.key, group.value, sectionIdx);
                      },
                      childCount: grouped.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Stat strip ────────────────────────────────────────────────────────────

  Widget _buildStatStrip(
      BuildContext context, List<LearningProgressModel> all) {
    final lessons = _totalLessons(all);
    final quizzes = _totalQuizzes(all);
    final xp = _totalXpEarned(all);
    final acc = _bestAccuracy(all);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          _statCell(context, '$lessons', 'Lessons', AppColors.primary),
          _vertDivider(context),
          _statCell(context, '$quizzes', 'Quizzes', AppColors.accent),
          _vertDivider(context),
          _statCell(context, '+$xp', 'XP Earned', AppColors.success),
          _vertDivider(context),
          _statCell(
            context,
            acc > 0 ? '${acc.toInt()}%' : '—',
            'Best Quiz',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _statCell(
      BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: context.textMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vertDivider(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: context.borderColor,
      );

  // ── Filter chip ───────────────────────────────────────────────────────────

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return TapScale(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : context.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : context.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : context.textMuted,
          ),
        ),
      ),
    );
  }

  // ── Section ───────────────────────────────────────────────────────────────

  Widget _buildSection(
    BuildContext context,
    String label,
    List<LearningProgressModel> items,
    int sectionIdx,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _sectionDotColor(label),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((e) {
          final delay = Duration(
              milliseconds: 60 * sectionIdx + 30 * e.key);
          return _buildItem(context, e.value)
              .animate()
              .fadeIn(delay: delay)
              .slideX(begin: 0.04, duration: 300.ms);
        }),
      ],
    );
  }

  Color _sectionDotColor(String label) {
    switch (label) {
      case 'Today':
        return AppColors.primary;
      case 'Yesterday':
        return AppColors.accent;
      case 'This week':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  // ── Activity item ─────────────────────────────────────────────────────────

  Widget _buildItem(BuildContext context, LearningProgressModel item) {
    final isQuiz = item.isQuiz;
    final title = item.displayTitle.isNotEmpty ? item.displayTitle : 'Lesson';
    final xp = item.xpEarned;
    final cat = item.categoryName;

    // Color accent per type
    final accent = isQuiz ? AppColors.accent : AppColors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon pill
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  isQuiz ? '🎯' : (item.isCompleted ? '✅' : '📖'),
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Time ago
                      Text(
                        _timeAgo(item.lastAccessedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textMuted,
                        ),
                      ),
                      // Category badge (if available)
                      if (cat.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 9,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      // Accuracy badge for quizzes
                      if (isQuiz && item.bestAccuracy > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${item.bestAccuracy.toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: _accuracyColor(item.bestAccuracy),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // XP chip
            if (xp > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$xp XP',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _accuracyColor(double acc) {
    if (acc >= 80) return AppColors.success;
    if (acc >= 60) return AppColors.warning;
    return AppColors.error;
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading activity…',
              style: TextStyle(color: context.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final label = _filter == 'quizzes'
        ? 'No quiz history yet'
        : _filter == 'lessons'
            ? 'No lessons completed yet'
            : 'No activity yet';
    final sub = _filter == 'all'
        ? 'Start a lesson or quiz to see your progress here.'
        : 'Switch filter to see other activity.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 0),
      child: Column(
        children: [
          Text(
            _filter == 'quizzes' ? '🎯' : '📖',
            style: const TextStyle(fontSize: 44),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(
                color: context.textMuted, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
