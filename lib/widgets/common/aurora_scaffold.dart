import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Wraps any screen body in a void-black Stack with two ambient
/// radial glow blobs (top-left teal, bottom-right cyan).
/// The child content sits on top of the glows.
class AuroraScaffold extends StatelessWidget {
  final Widget child;

  const AuroraScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Void background fill
        Positioned.fill(
          child: ColoredBox(
            color: isDark ? AppColorsDark.bgPrimary : AppColorsLight.bgPrimary,
          ),
        ),

        // Top-left teal glow blob
        Positioned(
          top: -120,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF14B8A6).withOpacity(isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom-right cyan glow blob
        Positioned(
          bottom: -100,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(isDark ? 0.12 : 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Screen content on top
        child,
      ],
    );
  }
}
