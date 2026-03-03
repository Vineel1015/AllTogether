import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/brand_colors.dart';

class MascotWidget extends StatefulWidget {
  final double size;
  const MascotWidget({super.key, this.size = 100});

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _eyeMovement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    // Funny side-to-side movement for googly eyes
    _eyeMovement = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MascotPainter(
            bobValue: _controller.value,
            eyeShift: _eyeMovement.value,
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double bobValue;
  final double eyeShift;

  _MascotPainter({required this.bobValue, required this.eyeShift});

  @override
  void paint(Canvas canvas, Size size) {
    // Position face higher so eyes are visible
    final center = Offset(size.width / 2, size.height / 1.8 + (bobValue * 2));
    final faceRadius = size.width / 2.5;

    // 1. Face (Orange Circle)
    final facePaint = Paint()..color = AllTogetherColors.mascotOrange;
    canvas.drawCircle(center, faceRadius, facePaint);

    // 2. Eyes (Large Blue Circles - Slightly off the face edge as in png)
    final eyePaint = Paint()..color = AllTogetherColors.mascotBlue;
    final eyeRadius = faceRadius * 0.45;
    // Eyes overlapping the edge of the face
    final leftEyeCenter = center + Offset(-faceRadius * 0.7, -faceRadius * 0.1);
    final rightEyeCenter = center + Offset(faceRadius * 0.7, -faceRadius * 0.1);
    canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);

    // 3. Pupils (Grey Circles - Funny side-to-side movement)
    final pupilPaint = Paint()..color = AllTogetherColors.mascotGrey;
    final pupilRadius = eyeRadius * 0.35;
    
    // Pupils move independently side to side
    final pupilOffset = Offset(eyeShift * (eyeRadius * 0.4), 0);
    canvas.drawCircle(leftEyeCenter + pupilOffset, pupilRadius, pupilPaint);
    canvas.drawCircle(rightEyeCenter + pupilOffset, pupilRadius, pupilPaint);

    // 4. Mouth (Blue Semi-Circle)
    final mouthPaint = Paint()..color = AllTogetherColors.mascotBlue;
    final mouthRect = Rect.fromCenter(
      center: center + Offset(0, faceRadius * 0.35),
      width: faceRadius * 1.2,
      height: faceRadius * 0.8,
    );
    canvas.drawArc(mouthRect, 0, pi, true, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => true;
}
