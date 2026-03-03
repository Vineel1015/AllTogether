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
    final center = Offset(size.width / 2, size.height / 2 + (bobValue * 5));
    final radius = size.width / 2.5;

    // Face
    final facePaint = Paint()..color = AllTogetherColors.mascotOrange;
    canvas.drawCircle(center, radius, facePaint);

    // Eye whites
    final whitePaint = Paint()..color = Colors.white;
    final leftEyeCenter = center + Offset(-radius / 2.5, -radius / 4);
    final rightEyeCenter = center + Offset(radius / 2.5, -radius / 4);
    canvas.drawCircle(leftEyeCenter, radius / 4, whitePaint);
    canvas.drawCircle(rightEyeCenter, radius / 4, whitePaint);

    // Pupils (Googly effect)
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(leftEyeCenter + eyeOffset, radius / 8, pupilPaint);
    canvas.drawCircle(rightEyeCenter + eyeOffset, radius / 8, pupilPaint);

    // Smile
    final smilePaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final smilePath = Path()
      ..addArc(
        Rect.fromCenter(center: center + Offset(0, radius / 4), width: radius, height: radius / 2),
        0.2,
        pi - 0.4,
      );
    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => true;
}
