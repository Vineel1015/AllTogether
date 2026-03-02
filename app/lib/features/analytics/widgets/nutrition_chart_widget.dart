import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/daily_nutrition_model.dart';

/// Bar chart showing calorie intake for each of the last 7 calendar days.
///
/// Days with no receipt data render a bar of height 0.
class NutritionChartWidget extends StatelessWidget {
  final List<DailyNutrition> dailyNutrition;

  const NutritionChartWidget({super.key, required this.dailyNutrition});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Last 7 days, oldest first
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    // Build lookup: 'yyyy-MM-dd' → totalCalories
    final byDate = <String, double>{};
    for (final d in dailyNutrition) {
      final key = _dateKey(d.date);
      byDate[key] = d.totalCalories;
    }

    final color = Theme.of(context).colorScheme.primary;
    final barGroups = days.asMap().entries.map((e) {
      final i = e.key;
      final day = e.value;
      final cal = byDate[_dateKey(day)] ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: cal, color: color, width: 20, borderRadius: BorderRadius.circular(4)),
        ],
      );
    }).toList();

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = days[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      weekdays[day.weekday - 1],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.shade700,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} kcal',
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
