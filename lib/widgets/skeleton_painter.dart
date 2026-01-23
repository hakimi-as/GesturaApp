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

    // Check if we have body data
    bool hasBody = pose != null && pose.isNotEmpty;

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

    final headPaint = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Helper to get coordinates
    Offset getPos(List? source, int index) {
      if (source == null || index >= source.length) return Offset.zero;
      var point = source[index];
      return Offset(point['x'] * size.width, point['y'] * size.height);
    }

    // ==========================================================
    // 1. OPTIMIZATION: Simulated Arms (If Body is Missing)
    // ==========================================================
    // If we only have hands, connect the wrist (Index 0) to the bottom of the screen
    // so they don't look like floating ghost hands.
    if (!hasBody) {
      if (leftHand != null && leftHand.isNotEmpty) {
        Offset wrist = getPos(leftHand, 0);
        // Draw line from wrist to bottom-left area to simulate an arm
        canvas.drawLine(wrist, Offset(wrist.dx - 20, size.height), ghostArmPaint);
      }
      if (rightHand != null && rightHand.isNotEmpty) {
        Offset wrist = getPos(rightHand, 0);
        // Draw line from wrist to bottom-right area
        canvas.drawLine(wrist, Offset(wrist.dx + 20, size.height), ghostArmPaint);
      }
    }

    // ==========================================================
    // 2. DRAW BODY (Arms & Shoulders) - Only if data exists
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

      // --- Draw Head ---
      Offset nose = getPos(pose, 0);
      Offset leftEar = getPos(pose, 7);
      Offset rightEar = getPos(pose, 8);
      
      double headRadius = 20.0;
      if (leftEar != Offset.zero && rightEar != Offset.zero) {
        headRadius = (leftEar - rightEar).distance * 1.5; 
      }
      headRadius = headRadius.clamp(15.0, 40.0);

      canvas.drawCircle(nose, headRadius, headPaint);
      
      // Draw Eyes
      final eyePaint = Paint()..color = Colors.black.withOpacity(0.7);
      canvas.drawCircle(nose.translate(-headRadius/3, -headRadius/4), 3, eyePaint);
      canvas.drawCircle(nose.translate(headRadius/3, -headRadius/4), 3, eyePaint);
    }

    // ==========================================================
    // 3. DRAW HANDS
    // ==========================================================
    
    void drawDetailedHand(List? handData) {
      if (handData == null || handData.isEmpty) return;

      // Helper to draw a specific chain of points
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
        
        // Draw tip
        canvas.drawCircle(getPos(handData, indices.last), 3.0, paint..style=PaintingStyle.fill);
      }

      // 1. Draw Palm (Base structure)
      final palmPaint = Paint()..color = Colors.white54..strokeWidth = 2.0;
      final palmConnections = [[0,1], [0,5], [5,9], [9,13], [13,17], [0,17]];
      
      for(var pair in palmConnections) {
        canvas.drawLine(getPos(handData, pair[0]), getPos(handData, pair[1]), palmPaint);
      }

      // 2. Draw Fingers (Color Coded)
      drawChain([1, 2, 3, 4],   Colors.redAccent);    // Thumb
      drawChain([5, 6, 7, 8],   Colors.orangeAccent); // Index
      drawChain([9, 10, 11, 12],Colors.yellowAccent); // Middle
      drawChain([13, 14, 15, 16],Colors.greenAccent); // Ring
      drawChain([17, 18, 19, 20],Colors.lightBlueAccent); // Pinky
    }

    drawDetailedHand(leftHand);
    drawDetailedHand(rightHand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}