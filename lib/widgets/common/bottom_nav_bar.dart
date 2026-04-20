import 'package:flutter/material.dart';
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
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        border: Border(
          top: BorderSide(color: context.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context: context, index: 0, label: loc.navHome,      painter: _HomeIconPainter()),
              _buildNavItem(context: context, index: 1, label: loc.navTranslate, painter: _SignIconPainter()),
              _buildNavItem(context: context, index: 2, label: loc.navLearn,     painter: _LearnIconPainter()),
              _buildNavItem(context: context, index: 3, label: loc.navSettings,  painter: _MeIconPainter()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required CustomPainter painter,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _ThemedIconPainter(
                  delegate: painter,
                  color: isActive ? AppColors.primary : context.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : context.textMuted,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Solid colour wrapper ────────────────────────────────────────────────────

class _ThemedIconPainter extends CustomPainter {
  final CustomPainter delegate;
  final Color color;

  _ThemedIconPainter({required this.delegate, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final shaderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.saveLayer(Offset.zero & size, Paint());
    delegate.paint(canvas, size);
    canvas.drawRect(Offset.zero & size, shaderPaint..blendMode = BlendMode.srcIn);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThemedIconPainter old) =>
      old.color != color || old.delegate != delegate;
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

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 4 * s, 14 * s, 14 * s), r), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(22 * s, 22 * s, 14 * s, 14 * s), r), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(22 * s, 4 * s, 14 * s, 14 * s), r), p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 22 * s, 14 * s, 14 * s), r), p);
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
    canvas.drawPath(shoulders, p);
  }

  @override
  bool shouldRepaint(_MeIconPainter old) => false;
}
