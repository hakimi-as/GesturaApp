/// Gestura Design System
/// Reusable decorations, widgets, and helpers that encode the visual language.
/// Import this alongside theme.dart — never alongside each other's internals.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

// ─── Radius system ───────────────────────────────────────────────────────────

/// Shared border-radius constants. Use these instead of magic numbers so
/// changing the visual language is a one-line edit.
class AppRadius {
  AppRadius._();
  static const double sm = 8;   // buttons, chips, small tiles
  static const double md = 14;  // compact cards, input fields
  static const double lg = 20;  // standard content cards
  static const double xl = 28;  // dialogs, hero containers, sheets
}

// ─── Decorations ─────────────────────────────────────────────────────────────

class AppDecorations {
  AppDecorations._();

  /// Standard content card — bordered, slight shadow.
  static BoxDecoration card(BuildContext context) => BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Compact tile card — tighter radius for stat tiles and list items.
  static BoxDecoration tileCard(BuildContext context) => BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.borderColor),
      );

  /// Card with a faint primary-colour glow border.
  static BoxDecoration glowCard(BuildContext context) => BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Solid-color hero card — for banners and feature CTAs.
  static BoxDecoration heroCard({
    Color color = AppColors.primary,
    double radius = AppRadius.xl,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Pill-shaped tag / badge.
  static BoxDecoration pill(Color color, {double opacity = 0.15}) =>
      BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      );
}

// ─── TapScale ─────────────────────────────────────────────────────────────────

/// Wraps any widget with a subtle scale-down press animation.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.965,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _anim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.forward();
  void _up(_) => _ctrl.reverse();
  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}

// ─── AppCard ─────────────────────────────────────────────────────────────────

/// Standardized card with consistent padding, border, and optional glow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool glow;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.glow = false,
    this.onTap,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = glow
        ? AppDecorations.glowCard(context)
        : AppDecorations.card(context);

    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration.copyWith(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return TapScale(onTap: onTap, child: content);
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────

/// Section heading with dot accent. If [emoji] is provided it replaces the dot.
/// Use [dotColor] to contextualise the section — pink for active/primary,
/// primary for standard, success for progress areas.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? emoji;
  final Color? dotColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.emoji,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
        ] else ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.familjenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── GradientButton ──────────────────────────────────────────────────────────

/// Full-width primary CTA button with gradient fill.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  final Widget? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.height = 56,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: onTap == null && !loading
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: onTap != null && !loading
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: GoogleFonts.familjenGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── StatusPill ──────────────────────────────────────────────────────────────

/// Small colour-coded badge/tag.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: AppDecorations.pill(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GlassCard ───────────────────────────────────────────────────────────────

/// Semi-transparent "glass" card — used on auth screens over gradient bg.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.20 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
