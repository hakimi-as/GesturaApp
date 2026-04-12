import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF060D0D).withOpacity(0.90)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.60),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14B8A6).withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
                label: AppLocalizations.of(context).navHome,
                painter: _HomeIconPainter(),
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
                label: AppLocalizations.of(context).navTranslate,
                painter: _SignIconPainter(),
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
                label: AppLocalizations.of(context).navLearn,
                painter: _LearnIconPainter(),
              ),
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
                label: AppLocalizations.of(context).navSettings,
                painter: _MeIconPainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Function(int) onTap;
  final String label;
  final CustomPainter painter;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.label,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(
                painter: _GradientIconPainter(
                  delegate: painter,
                  isActive: isActive,
                  isDark: isDark,
                ),
              ),
            )
                .animate(key: ValueKey('icon_${index}_$isActive'))
                .scale(
                  begin: isActive
                      ? const Offset(0.75, 0.75)
                      : const Offset(1.0, 1.0),
                  end: isActive
                      ? const Offset(1.0, 1.0)
                      : const Offset(0.75, 0.75),
                  duration: 250.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 150.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient colour wrapper ─────────────────────────────────────────────────

class _GradientIconPainter extends CustomPainter {
  final CustomPainter delegate;
  final bool isActive;
  final bool isDark;

  _GradientIconPainter({
    required this.delegate,
    required this.isActive,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = isActive
        ? const LinearGradient(
            colors: [Colors.white, Color(0xFFCCFBF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              (isDark ? Colors.white : const Color(0xFF0D9488))
                  .withOpacity(0.38),
              (isDark ? Colors.white : const Color(0xFF0D9488))
                  .withOpacity(0.38),
            ],
          );

    final shaderPaint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.saveLayer(Offset.zero & size, Paint());
    delegate.paint(canvas, size);
    canvas.drawRect(
        Offset.zero & size, shaderPaint..blendMode = BlendMode.srcIn);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GradientIconPainter old) =>
      old.isActive != isActive || old.isDark != isDark;
}

// ─── Icon painters ────────────────────────────────────────────────────────────

class _HomeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final s = size.width / 40;

    // Chimney
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(25 * s, 7 * s, 5 * s, 9 * s),
        const Radius.circular(1.5),
      ),
      p,
    );

    // House body
    final body = Path()
      ..moveTo(20 * s, 5 * s)
      ..lineTo(6 * s, 16.5 * s)
      ..lineTo(6 * s, 35 * s)
      ..lineTo(16 * s, 35 * s)
      ..lineTo(16 * s, 26 * s)
      ..arcToPoint(
        Offset(24 * s, 26 * s),
        radius: Radius.circular(4 * s),
        clockwise: false,
      )
      ..lineTo(24 * s, 35 * s)
      ..lineTo(34 * s, 35 * s)
      ..lineTo(34 * s, 16.5 * s)
      ..close();
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(_HomeIconPainter old) => false;
}

class _SignIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer circle
    canvas.drawCircle(Offset(20 * s, 20 * s), 14 * s, p);

    // Corner brackets
    final brackets = Path()
      ..moveTo(8 * s, 14 * s)
      ..lineTo(8 * s, 8 * s)
      ..lineTo(14 * s, 8 * s)
      ..moveTo(26 * s, 8 * s)
      ..lineTo(32 * s, 8 * s)
      ..lineTo(32 * s, 14 * s)
      ..moveTo(8 * s, 26 * s)
      ..lineTo(8 * s, 32 * s)
      ..lineTo(14 * s, 32 * s)
      ..moveTo(26 * s, 32 * s)
      ..lineTo(32 * s, 32 * s)
      ..lineTo(32 * s, 26 * s);
    canvas.drawPath(brackets, p);

    // Centre dot
    canvas.drawCircle(
      Offset(20 * s, 20 * s),
      3.5 * s,
      Paint()..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SignIconPainter old) => false;
}

class _LearnIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final s = size.width / 40;
    const r = Radius.circular(3.5);

    // Top-left + bottom-right — full opacity (handled by gradient wrapper)
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4*s, 4*s, 14*s, 14*s), r), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(22*s, 22*s, 14*s, 14*s), r), p);

    // Top-right + bottom-left — dim 45% (paint with reduced alpha directly)
    final dim = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.45);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(22*s, 4*s, 14*s, 14*s), r), dim);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4*s, 22*s, 14*s, 14*s), r), dim);
  }

  @override
  bool shouldRepaint(_LearnIconPainter old) => false;
}

class _MeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final s = size.width / 40;

    // Head
    canvas.drawCircle(Offset(20 * s, 14 * s), 7 * s, p);

    // Shoulders
    final shoulders = Path()
      ..moveTo(6 * s, 38 * s)
      ..quadraticBezierTo(6 * s, 22 * s, 20 * s, 22 * s)
      ..quadraticBezierTo(34 * s, 22 * s, 34 * s, 38 * s)
      ..close();
    canvas.drawPath(
      shoulders,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.60),
    );
  }

  @override
  bool shouldRepaint(_MeIconPainter old) => false;
}
