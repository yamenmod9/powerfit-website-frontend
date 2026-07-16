import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/helpers.dart';
import 'dashboard_shell.dart';

const _axisStyle = TextStyle(
  color: DashColors.subtle,
  fontSize: 10.5,
  fontWeight: FontWeight.w600,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Axis ticks are read at a glance and stack vertically, so they compact rather
/// than spell out every digit of a six-figure total.
String _compactAxisValue(double value) {
  final abs = value.abs();
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) {
    return '${(value / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}K';
  }
  return value.toStringAsFixed(0);
}

/// Revenue over time — one point per period, as returned by
/// /api/reports/revenue-trend.
///
/// One series, so there is no legend: the section title already names what is
/// plotted, and a one-swatch box would just restate it. Values are carried by
/// the y-axis ticks and the touch tooltip rather than a number on every point.
class DashRevenueTrendChart extends StatelessWidget {
  /// Points from the endpoint: `{date, label, revenue, transactions}`.
  final List<dynamic> points;
  final double height;

  const DashRevenueTrendChart({
    super.key,
    required this.points,
    this.height = 220,
  });

  static double _revenueOf(dynamic point) =>
      ((point['revenue'] ?? 0) as num).toDouble();

  static String _labelOf(dynamic point) => (point['label'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            S.noRevenueData,
            style: const TextStyle(color: DashColors.subtle, fontSize: 13),
          ),
        ),
      );
    }

    final revenues = [for (final point in points) _revenueOf(point)];
    final peak = revenues.reduce(math.max);

    // A period with no sales genuinely earned nothing, so a flat zero series is
    // the truth — but it still needs a non-degenerate axis to draw against.
    final maxY = peak <= 0 ? 1.0 : peak * 1.15;
    final gridInterval = maxY / 4;

    // Aim for ~5 x labels whatever the bucket count, so they never collide.
    final labelEvery = math.max(1, (points.length / 5).ceil());

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: gridInterval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: DashColors.line,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: gridInterval,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    _compactAxisValue(value),
                    style: _axisStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Always keep the most recent label; thin the rest out.
                  final isLast = index == points.length - 1;
                  if (!isLast && index % labelEvery != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_labelOf(points[index]), style: _axisStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: DashColors.inner,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) => [
                for (final spot in touchedSpots)
                  LineTooltipItem(
                    '${_labelOf(points[spot.x.toInt()])}\n',
                    const TextStyle(
                      color: DashColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: NumberHelper.formatCurrency(spot.y),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < revenues.length; i++)
                  FlSpot(i.toDouble(), revenues[i]),
              ],
              color: DashColors.chartRevenue,
              barWidth: 2,
              // Straight segments: a curve would invent revenue between periods
              // that never happened.
              isCurved: false,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: DashColors.chartRevenue,
                  // A surface-colored ring keeps a dot legible where it sits on
                  // the line or against the area wash.
                  strokeWidth: 2,
                  strokeColor: DashColors.card,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: DashColors.chartRevenue.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The revenue trend as a ready dashboard card: granularity toggle + chart.
///
/// The owner and accountant consoles plot the same series from their own
/// providers, so the card is assembled once here rather than per role.
class DashRevenueTrendCard extends StatelessWidget {
  final List<dynamic> points;

  /// Active bucket: `daily` | `weekly` | `monthly`.
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final Color accent;

  const DashRevenueTrendCard({
    super.key,
    required this.points,
    required this.period,
    required this.onPeriodChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DashSectionCard(
      title: S.revenueTrend,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Granularity, not a data filter — the console's branch and date
          // controls scope every card alike, while this only changes how finely
          // this one series is bucketed.
          Row(
            children: [
              for (final option in const ['daily', 'weekly', 'monthly']) ...[
                _PeriodChip(
                  label: S.trendPeriodLabel(option),
                  selected: option == period,
                  accent: accent,
                  onTap: () => onPeriodChanged(option),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          DashRevenueTrendChart(points: points),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : DashColors.inner,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? accent : DashColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : DashColors.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Expenses by category as a ready dashboard card.
class DashExpenseCategoryCard extends StatelessWidget {
  final List<dynamic> categories;
  final Color accent;

  const DashExpenseCategoryCard({
    super.key,
    required this.categories,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DashSectionCard(
      title: S.expensesByCategory,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The breakdown counts approved spend only, matching how the money
          // page keeps pending out of its net.
          Text(
            S.approvedExpenses,
            style: const TextStyle(color: DashColors.subtle, fontSize: 11.5),
          ),
          const SizedBox(height: 16),
          DashCategoryBreakdown(categories: categories),
        ],
      ),
    );
  }
}

/// Expense totals by category, as returned by /api/reports/expenses-by-category.
///
/// Every bar wears one hue: expense categories are nominal, so shading them by
/// size would double-encode bar length as color and burn the only free channel
/// on something the length already says. Identity comes from the row labels.
///
/// Horizontal bars because category names are long and numerous — the same
/// reason [DashProgressRow] exists, which this reuses rather than reinventing.
class DashCategoryBreakdown extends StatelessWidget {
  /// Categories from the endpoint: `{category, total, count}`, richest first.
  final List<dynamic> categories;

  /// Rows past this fold into a single "Other" row rather than running long.
  final int maxRows;

  const DashCategoryBreakdown({
    super.key,
    required this.categories,
    this.maxRows = 6,
  });

  static double _totalOf(dynamic category) =>
      ((category['total'] ?? 0) as num).toDouble();

  static String _nameOf(dynamic category) =>
      (category['category'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.pie_chart_outline,
                  size: 40, color: DashColors.subtle),
              const SizedBox(height: 10),
              Text(
                S.noExpensesFound,
                style: const TextStyle(color: DashColors.subtle, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // The endpoint sorts richest-first; fold the tail so the chart never grows
    // an unbounded number of rows.
    final shown = categories.take(maxRows).toList();
    final tail = categories.skip(maxRows).toList();
    final tailTotal = tail.fold<double>(0, (sum, c) => sum + _totalOf(c));

    final rows = <({String label, double total})>[
      for (final category in shown)
        (label: S.expenseCategoryLabel(_nameOf(category)), total: _totalOf(category)),
      if (tail.isNotEmpty) (label: S.otherCategories(tail.length), total: tailTotal),
    ];

    // Scale against the largest row so the widest bar fills its track.
    final peak = rows.fold<double>(0, (m, r) => math.max(m, r.total));

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          DashProgressRow(
            accent: DashColors.chartExpense,
            name: rows[i].label,
            trailing: NumberHelper.formatCurrency(rows[i].total),
            fraction: peak <= 0 ? 0 : rows[i].total / peak,
          ),
          if (i < rows.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}
