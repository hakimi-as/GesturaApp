import 'package:flutter/material.dart';

class SkeletonPainter extends CustomPainter {
  final Map<String, dynamic> frameData;

  SkeletonPainter(this.frameData);

  @override
  void paint(Canvas canvas, Size size) {
    // Extract parts
    final pose = frameData['pose'] as List?;
    final leftHand = frameData['left_hand'] as List?;
    final rightHand = frameData['right_hand'] as List?;
    final face = frameData['face'] as List?;

    // Check availability
    bool hasBody = pose != null && pose.isNotEmpty;
    bool hasFace = face != null && face.isNotEmpty;

    // --- Paint Styles ---
    final bonePaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final ghostArmPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.tealAccent, Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Determine whether this is a sign.mt/ASL sign (no head/face landmarks,
    // but has body landmarks). sign.mt fills the full 512x512 frame so we
    // scale it down and add top padding to keep the head inside the canvas.
    final bool isSignMtData = (pose != null && pose.isNotEmpty) &&
        (face == null || face.isEmpty) &&
        (pose.length > 12) &&
        (pose[0] is Map && (pose[0]['x'] as num).toDouble() == 0.0 && (pose[0]['y'] as num).toDouble() == 0.0);

    // Helper to get coordinates
    Offset getPos(List? source, int index) {
      if (source == null || index >= source.length) return Offset.zero;
      var point = source[index];
      double x = (point['x'] as num).toDouble();
      double y = (point['y'] as num).toDouble();
      if (x == 0.0 && y == 0.0) return Offset.zero;
      if (isSignMtData) {
        // Flip x: sign.mt uses standard image coords (signer's right hand
        // appears on the LEFT of the image). Flip so it matches BIM/selfie
        // convention where right hand appears on the right side.
        x = 1.0 - x;
        // Scale to 50% + 18% top padding so the figure fits the canvas.
        const scale = 0.50;
        const padTop = 0.18;
        x = (x - 0.5) * scale + 0.5;
        y = y * scale + padTop;
      }
      return Offset(x * size.width, y * size.height);
    }

    // ==========================================================
    // 1. OPTIMIZATION: Simulated Arms (If Body is Missing)
    // ==========================================================
    if (!hasBody) {
      if (leftHand != null && leftHand.isNotEmpty) {
        Offset wrist = getPos(leftHand, 0);
        canvas.drawLine(wrist, Offset(wrist.dx - 20, size.height), ghostArmPaint);
      }
      if (rightHand != null && rightHand.isNotEmpty) {
        Offset wrist = getPos(rightHand, 0);
        canvas.drawLine(wrist, Offset(wrist.dx + 20, size.height), ghostArmPaint);
      }
    }

    // ==========================================================
    // 2. DRAW BODY (Torso & Arms)
    // ==========================================================
    if (hasBody) {
      final bodyConnections = [
        [11, 12], // Shoulders
        [11, 13], [13, 15], // Left Arm
        [12, 14], [14, 16], // Right Arm
        [11, 23], [12, 24], [23, 24], // Torso
      ];

      for (var pair in bodyConnections) {
        if (pair[0] < pose.length && pair[1] < pose.length) {
          canvas.drawLine(getPos(pose, pair[0]), getPos(pose, pair[1]), bonePaint);
        }
      }
    }

    // ==========================================================
    // 3. DRAW HEAD / FACE
    // ==========================================================

    if (hasFace) {
      // --- A. REAL FACE EXPRESSION (From JSON) ---
      final facePaint = Paint()
        ..color = Colors.yellowAccent.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      void drawLoop(List<int> indices, {bool close = true}) {
        Path path = Path();
        if (indices.isEmpty) return;
        path.moveTo(getPos(face, indices[0]).dx, getPos(face, indices[0]).dy);
        for (int i = 1; i < indices.length; i++) {
          Offset p = getPos(face, indices[i]);
          path.lineTo(p.dx, p.dy);
        }
        if (close) path.close();
        canvas.drawPath(path, facePaint);
      }

      // Lips
      drawLoop([61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]);
      drawLoop([78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308, 415, 310, 311, 312, 13, 82, 81, 80, 191]);

      // Left Eye
      drawLoop([33, 160, 158, 133, 153, 144, 145, 153]);
      // Right Eye
      drawLoop([362, 385, 387, 263, 373, 380, 374, 373]);

      // Left Eyebrow
      drawLoop([70, 63, 105, 66, 107, 55, 65, 52, 53, 46], close: false);
      // Right Eyebrow
      drawLoop([336, 296, 334, 293, 300, 276, 283, 282, 295, 285], close: false);

      // Face Oval
      drawLoop([10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109]);

    } else if (hasBody) {
      // --- B. FALLBACK: YELLOW CIRCLE HEAD ---
      final headPaint = Paint()
        ..color = Colors.yellowAccent.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      Offset nose = getPos(pose, 0);
      Offset leftEar = getPos(pose, 7);
      Offset rightEar = getPos(pose, 8);

      // If nose/ears are missing (e.g. sign.mt data only has 8 body points),
      // estimate the head position above the shoulder midpoint.
      final leftShoulder = getPos(pose, 11);
      final rightShoulder = getPos(pose, 12);
      final hasShoulders = leftShoulder != Offset.zero && rightShoulder != Offset.zero;

      if (nose == Offset.zero && hasShoulders) {
        final shoulderMid = Offset(
          (leftShoulder.dx + rightShoulder.dx) / 2,
          (leftShoulder.dy + rightShoulder.dy) / 2,
        );
        final shoulderWidth = (leftShoulder - rightShoulder).distance;
        final headRadius = (shoulderWidth * 0.45).clamp(15.0, 45.0);
        // Place head above shoulders by one head-diameter
        nose = shoulderMid.translate(0, -(headRadius * 2.2));
        canvas.drawCircle(nose, headRadius, headPaint);
        final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
        canvas.drawCircle(nose.translate(-headRadius / 3, -headRadius / 4), 3, eyePaint);
        canvas.drawCircle(nose.translate(headRadius / 3, -headRadius / 4), 3, eyePaint);
      } else {
        double headRadius = 20.0;
        if (leftEar != Offset.zero && rightEar != Offset.zero) {
          headRadius = (leftEar - rightEar).distance * 1.5;
        }
        headRadius = headRadius.clamp(15.0, 40.0);
        canvas.drawCircle(nose, headRadius, headPaint);
        final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
        canvas.drawCircle(nose.translate(-headRadius/3, -headRadius/4), 3, eyePaint);
        canvas.drawCircle(nose.translate(headRadius/3, -headRadius/4), 3, eyePaint);
      }
    }

    // ==========================================================
    // 4. DRAW HANDS
    // ==========================================================

    void drawDetailedHand(List? handData) {
      if (handData == null || handData.isEmpty) return;

      void drawChain(List<int> indices, Color color) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

        for (int i = 0; i < indices.length - 1; i++) {
          final p1 = getPos(handData, indices[i]);
          final p2 = getPos(handData, indices[i+1]);
          canvas.drawLine(p1, p2, paint);
        }
        canvas.drawCircle(getPos(handData, indices.last), 3.0, paint..style=PaintingStyle.fill);
      }

      // Palm
      final palmPaint = Paint()..color = Colors.white54..strokeWidth = 2.0;
      final palmConnections = [[0,1], [0,5], [5,9], [9,13], [13,17], [0,17]];

      for(var pair in palmConnections) {
        canvas.drawLine(getPos(handData, pair[0]), getPos(handData, pair[1]), palmPaint);
      }

      // Fingers
      drawChain([1, 2, 3, 4],   Colors.redAccent);
      drawChain([5, 6, 7, 8],   Colors.orangeAccent);
      drawChain([9, 10, 11, 12],Colors.yellowAccent);
      drawChain([13, 14, 15, 16],Colors.greenAccent);
      drawChain([17, 18, 19, 20],Colors.lightBlueAccent);
    }

    drawDetailedHand(leftHand);
    drawDetailedHand(rightHand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
