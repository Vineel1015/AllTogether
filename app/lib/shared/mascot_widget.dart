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
  Offset _eyeOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final center = Offset(widget.size / 2, widget.size / 2);
        final dir = event.localPosition - center;
        final dist = min(dir.distance / 10, 8.0);
        setState(() {
          _eyeOffset = Offset.fromDirection(dir.direction, dist);
        });
      },
      onExit: (_) => setState(() => _eyeOffset = Offset.zero),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MascotPainter(
              bobValue: _controller.value,
              eyeOffset: _eyeOffset,
            ),
          );
        },
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double bobValue;
  final Offset eyeOffset;

  _MascotPainter({required this.bobValue, required this.eyeOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Position mascot slightly lower to create 'peeping' effect
    final center = Offset(size.width / 2, size.height / 1.5 + (bobValue * 3));
    final faceRadius = size.width / 2.2;

    // 1. Face (Orange Circle)
    final facePaint = Paint()..color = AllTogetherColors.mascotOrange;
    canvas.drawCircle(center, faceRadius, facePaint);

    // 2. Eyes (Large Blue Circles - Fixed Position)
    final eyePaint = Paint()..color = AllTogetherColors.mascotBlue;
    final eyeRadius = faceRadius * 0.35;
    final leftEyeCenter = center + Offset(-faceRadius * 0.45, -faceRadius * 0.1);
    final rightEyeCenter = center + Offset(faceRadius * 0.45, -faceRadius * 0.1);
    canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);

    // 3. Pupils (Grey Circles - Moving)
    final pupilPaint = Paint()..color = AllTogetherColors.mascotGrey;
    final pupilRadius = eyeRadius * 0.3;
    // Limit pupil movement within the blue eye
    final limitedOffset = Offset(
      eyeOffset.dx.clamp(-pupilRadius, pupilRadius),
      eyeOffset.dy.clamp(-pupilRadius, pupilRadius),
    );
    canvas.drawCircle(leftEyeCenter + limitedOffset, pupilRadius, pupilPaint);
    canvas.drawCircle(rightEyeCenter + limitedOffset, pupilRadius, pupilPaint);

    // 4. Mouth (Blue Semi-Circle at bottom)
    final mouthPaint = Paint()..color = AllTogetherColors.mascotBlue;
    final mouthRect = Rect.fromCenter(
      center: center + Offset(0, faceRadius * 0.4),
      width: faceRadius * 1.1,
      height: faceRadius * 0.7,
    );
    canvas.drawArc(mouthRect, 0, pi, true, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => true;
}
