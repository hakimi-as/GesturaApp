/// Aurora Glass UI — shared primitives for the Gestura redesign.
///
/// Every screen in the app should use these components instead of raw Material
/// widgets so the visual language stays consistent.
library glass_ui;

import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

/// Primary asymmetric corners: top-left/bottom-right 20, others 6.
const kGlassRadius = BorderRadius.only(
  topLeft:     Radius.circular(20),
  topRight:    Radius.circular(6),
  bottomLeft:  Radius.circular(6),
  bottomRight: Radius.circular(20),
);

/// Alternate asymmetric corners: top-right/bottom-left 16, others 4.
const kGlassRadiusAlt = BorderRadius.only(
  topLeft:     Radius.circular(4),
  topRight:    Radius.circular(16),
  bottomLeft:  Radius.circular(16),
  bottomRight: Radius.circular(4),
);

/// Full pill radius.
const kPillRadius = BorderRadius.all(Radius.circular(100));

// ─── GlassCard ────────────────────────────────────────────────────────────────

/// A frosted-glass surface card.
///
/// [alternate] flips to the alternate asymmetric corner set.
/// [padding] defaults to 16 all sides.
/// [gradient] overlays a gradient on the glass surface (e.g. teal gradient on
/// welcome card).
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool alternate;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final BoxDecoration? decorationOverride;

  const GlassCard({
    super.key,
    required this.child,
    this.alternate = false,
    this.padding,
    this.gradient,
    this.decorationOverride,
  });

  @override
  Widget build(BuildContext context) {
    final base = alternate
        ? AppColors.glassCard(alternate: true)
        : AppColors.glassCard();

    final decoration = decorationOverride ??
        (gradient != null ? base.copyWith(gradient: gradient) : base);

    return Container(
      decoration: decoration,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ─── GlassPrimaryButton ───────────────────────────────────────────────────────

/// Full-width teal gradient primary action button.
class GlassPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onPressed == null ? const Color(0xFF1A3030) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── GlassOutlineButton ───────────────────────────────────────────────────────

/// Outlined teal button — use for secondary actions.
class GlassOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GlassOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 18, color: AppColors.primary)
            : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── GlassTextField ───────────────────────────────────────────────────────────

/// Text input styled to match the glass design system.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColorsDark.textMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: AppColorsDark.textPrimary),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColorsDark.textMuted),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColorsDark.textMuted, size: 20)
                : null,
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: const Color(0xFF0D1A1A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: kGlassRadius,
              borderSide: const BorderSide(
                color: AppColorsDark.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kGlassRadius,
              borderSide: const BorderSide(
                color: AppColorsDark.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kGlassRadius,
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: kGlassRadius,
              borderSide: const BorderSide(
                color: AppColorsDark.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: kGlassRadius,
              borderSide: const BorderSide(
                color: AppColorsDark.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── GlassAppBar ──────────────────────────────────────────────────────────────

/// Transparent app bar with teal-accented title.
///
/// Use as the [appBar] of a Scaffold on push-navigated screens.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: showBack,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: AppColors.primary,
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: actions,
    );
  }
}

// ─── GlassSectionHeader ───────────────────────────────────────────────────────

/// "SECTION TITLE" — 9 px, all-caps, letter-spaced label.
class GlassSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const GlassSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: AppColorsDark.textMuted,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── GlassTile ────────────────────────────────────────────────────────────────

/// A list tile with glass border and asymmetric corners.
class GlassTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool alternate;
  final EdgeInsetsGeometry? padding;

  const GlassTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.alternate = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppColors.glassCard(alternate: alternate),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColorsDark.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: AppColorsDark.textMuted,
                        fontSize: 12,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

// ─── GlassIconButton ──────────────────────────────────────────────────────────

/// Square icon button with glass fill — use in app bar actions and quick taps.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: AppColors.glassCard(),
        child: Icon(
          icon,
          color: iconColor ?? AppColorsDark.textPrimary,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// ─── GlassChip ────────────────────────────────────────────────────────────────

/// Small tag chip — teal outline on active, glass on inactive.
class GlassChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const GlassChip({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.10),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColorsDark.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── GlassBadge ───────────────────────────────────────────────────────────────

/// Circular notification badge.
class GlassBadge extends StatelessWidget {
  final int count;

  const GlassBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── GlassEmptyState ──────────────────────────────────────────────────────────

/// Empty state with icon, title, and optional action.
class GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColorsDark.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColorsDark.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              GlassPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── GlassProgressBar ────────────────────────────────────────────────────────

/// Teal progress bar with glass track.
class GlassProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final double height;

  const GlassProgressBar({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
      ),
    );
  }
}

// ─── TealGradientIcon ─────────────────────────────────────────────────────────

/// Circular teal gradient icon container — use in stats, features, etc.
class TealGradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const TealGradientIcon({super.key, required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}
