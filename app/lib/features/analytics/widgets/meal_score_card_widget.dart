import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finder/models/meal_score_model.dart';
import '../../finder/providers/meal_scoring_provider.dart';
import '../../finder/providers/weekly_plan_provider.dart';

/// Card shown at the top of the Analytics screen.
///
/// Displays a circular arc gauge with the user's composite plan score,
/// sub-scores for health and sustainability, and a grade letter.
/// Shows an empty state when no meals have been added to the plan.
class MealScoreCardWidget extends ConsumerWidget {
  const MealScoreCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(weeklyPlanNotifierProvider);
    final planScore = ref.watch(userPlanScoreProvider);

    return scoreAsync.when(
      loading: () => const _ScoreCardShell(child: _LoadingBody()),
      error: (_, __) => const _ScoreCardShell(child: _EmptyBody()),
      data: (_) {
        if (planScore == null) {
          return const _ScoreCardShell(child: _EmptyBody());
        }

        final plan = ref.read(weeklyPlanNotifierProvider).valueOrNull;
        final service = ref.read(mealScoringServiceProvider);

        // Compute average sub-scores across all meals in plan.
        final meals = plan?.meals ?? [];
        double avgHealth = 0;
        double avgSustainability = 0;
        if (meals.isNotEmpty) {
          final scores = meals.map(service.scoreMeal).toList();
          avgHealth =
              scores.map((s) => s.healthScore).reduce((a, b) => a + b) /
                  scores.length;
          avgSustainability =
              scores.map((s) => s.sustainabilityScore).reduce((a, b) => a + b) /
                  scores.length;
        }

        final compositeScore = MealScore.fromScores(avgHealth, avgSustainability);
        return _ScoreCardShell(
          child: _ScoreBody(score: compositeScore),
        );
      },
    );
  }
}

// ── Shell ──────────────────────────────────────────────────────────────────

class _ScoreCardShell extends StatelessWidget {
  final Widget child;

  const _ScoreCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.assessment_outlined, size: 40, color: Colors.grey),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            'Add meals to your plan to see your score',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ── Loading ────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Score body ─────────────────────────────────────────────────────────────

class _ScoreBody extends StatelessWidget {
  final MealScore score;

  const _ScoreBody({required this.score});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradeColor = score.gradeColor(colorScheme);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Circular arc gauge
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _ArcGaugePainter(
                  progress: score.compositeScore / 100,
                  color: gradeColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.grade,
                        style: textTheme.displaySmall?.copyWith(
                          color: gradeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${score.compositeScore.toStringAsFixed(0)}/100',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Sub-score rows
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.gradeDescription,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SubScoreRow(
                    label: 'Health',
                    score: score.healthScore,
                    icon: Icons.favorite_outline,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 6),
                  _SubScoreRow(
                    label: 'Sustainability',
                    score: score.sustainabilityScore,
                    icon: Icons.eco_outlined,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _tagline(score.grade),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _tagline(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent – keep it up!';
      case 'B':
        return 'Good choices – a little more variety will push you to A!';
      case 'C':
        return 'Fair – try swapping some ingredients for greener options.';
      case 'D':
        return 'Poor – consider adding more plant-based meals.';
      default:
        return 'Very poor – try replacing high-impact ingredients.';
    }
  }
}

// ── Sub-score row ──────────────────────────────────────────────────────────

class _SubScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;

  const _SubScoreRow({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        SizedBox(
          width: 90,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          '${score.toStringAsFixed(0)}/100',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

// ── Arc gauge painter ──────────────────────────────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color color;

  const _ArcGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 8.0;
    const startAngle = math.pi * 0.75; // start at bottom-left
    const sweepAngle = math.pi * 1.5;  // 270° arc

    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.progress != progress || old.color != color;
}
