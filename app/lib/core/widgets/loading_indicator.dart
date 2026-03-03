import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen centered loading indicator using an animated recycling symbol.
///
/// Three arrows cycle one at a time — each highlighted green in sequence —
/// echoing the app's sustainability theme.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: _RecycleSpinner());
  }
}

// ── Spinner widget ────────────────────────────────────────────────────────────

class _RecycleSpinner extends StatefulWidget {
  const _RecycleSpinner();

  @override
  State<_RecycleSpinner> createState() => _RecycleSpinnerState();
}

class _RecycleSpinnerState extends State<_RecycleSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _active = (_active + 1) % 3);
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: CustomPaint(painter: _RecyclePainter(activeArrow: _active)),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _RecyclePainter extends CustomPainter {
  const _RecyclePainter({required this.activeArrow});

  final int activeArrow;

  static const _green = Color(0xFF4CAF50);
  static const _grey = Color(0xFFBDBDBD);

  // Each arc spans 100°, spaced 120° apart → 20° gap between arrows.
  static const _arcSpan = 100.0 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final strokeWidth = size.shortestSide * 0.11;

    for (int i = 0; i < 3; i++) {
      // Arrow 0 starts at top (-90°), each subsequent arrow +120°.
      final startAngle = -math.pi / 2 + i * (2 * math.pi / 3);
      _drawArrow(
        canvas: canvas,
        center: center,
        radius: radius,
        startAngle: startAngle,
        color: i == activeArrow ? _green : _grey,
        strokeWidth: strokeWidth,
      );
    }
  }

  void _drawArrow({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required Color color,
    required double strokeWidth,
  }) {
    final endAngle = startAngle + _arcSpan;

    // ── Arc body ──────────────────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      _arcSpan - 0.04, // trim slightly so arc doesn't overlap arrowhead
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── Arrowhead ─────────────────────────────────────────────────────────────
    // Tip sits on the arc at endAngle.
    final tip = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    // Tangent direction at endAngle for a clockwise arc (increasing θ).
    final tanDx = -math.sin(endAngle);
    final tanDy = math.cos(endAngle);

    // Radial direction at endAngle (perpendicular to tangent).
    final perpDx = math.cos(endAngle);
    final perpDy = math.sin(endAngle);

    final aLen = strokeWidth * 1.4; // how far back the base sits
    final aWidth = strokeWidth * 0.85; // half-width of arrowhead base

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          tip.dx - tanDx * aLen + perpDx * aWidth,
          tip.dy - tanDy * aLen + perpDy * aWidth,
        )
        ..lineTo(
          tip.dx - tanDx * aLen - perpDx * aWidth,
          tip.dy - tanDy * aLen - perpDy * aWidth,
        )
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RecyclePainter old) => old.activeArrow != activeArrow;
}
