import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';

/// Analytics page showing spending insights with charts
class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  PeriodAnalytics? _weeklyAnalytics;
  PeriodAnalytics? _monthlyAnalytics;
  PeriodAnalytics? _yearlyAnalytics;
  Map<int, double> _dailySpending = {};
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final weekly = await _analyticsService.getWeeklyAnalytics();
      final monthly = await _analyticsService.getMonthlyAnalytics();
      final yearly = await _analyticsService.getYearlyAnalytics();
      final daily = await _analyticsService.getDailySpendingForMonth();

      if (mounted) {
        setState(() {
          _weeklyAnalytics = weekly;
          _monthlyAnalytics = monthly;
          _yearlyAnalytics = yearly;
          _dailySpending = daily;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  PeriodAnalytics? get _currentAnalytics {
    switch (_selectedPeriod) {
      case 'weekly':
        return _weeklyAnalytics;
      case 'monthly':
        return _monthlyAnalytics;
      case 'yearly':
        return _yearlyAnalytics;
      default:
        return _monthlyAnalytics;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'weekly', label: Text('Week')),
                        ButtonSegment(value: 'monthly', label: Text('Month')),
                        ButtonSegment(value: 'yearly', label: Text('Year')),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedPeriod = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Total spending card
                    if (_currentAnalytics != null) ...[
                      _buildSpendingCard(currency),
                      const SizedBox(height: 16),
                      _buildComparisonCard(currency),
                      const SizedBox(height: 24),

                      // Daily spending chart
                      if (_dailySpending.isNotEmpty) ...[
                        const Text(
                          'Daily Spending This Month',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _buildBarChart(currency),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Spending trend line chart
                      const Text(
                        'Spending Trend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildLineChart(currency),
                      ),
                      const SizedBox(height: 24),

                      _buildStatsGrid(),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No data available'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBarChart(Currency currency) {
    final sortedDays = _dailySpending.keys.toList()..sort();
    if (sortedDays.isEmpty) {
      return const Center(child: Text('No spending data'));
    }

    final maxY = _dailySpending.values.reduce((a, b) => a > b ? a : b);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Day ${sortedDays[groupIndex]}\n${currency.symbol}${rod.toY.toStringAsFixed(0)}',
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDays.length) {
                  if (sortedDays[index] % 5 == 0 || index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${sortedDays[index]}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        barGroups: List.generate(sortedDays.length, (index) {
          final day = sortedDays[index];
          final value = _dailySpending[day] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    primaryColor,
                    primaryColor.withAlpha(180),
                  ],
                ),
                width: sortedDays.length > 15 ? 8 : 14,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY * 1.2,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeOutQuart,
    );
  }

  Widget _buildLineChart(Currency currency) {
    final sortedDays = _dailySpending.keys.toList()..sort();
    if (sortedDays.isEmpty) {
      return const Center(child: Text('No spending data'));
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    // Calculate cumulative spending
    double cumulative = 0;
    final cumulativeData = <FlSpot>[];
    for (int i = 0; i < sortedDays.length; i++) {
      cumulative += _dailySpending[sortedDays[i]] ?? 0;
      cumulativeData.add(FlSpot(i.toDouble(), cumulative));
    }

    final maxY = cumulative * 1.1;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dayIndex = spot.spotIndex;
                final day = dayIndex < sortedDays.length ? sortedDays[dayIndex] : 0;
                return LineTooltipItem(
                  'Day $day\n${currency.symbol}${spot.y.toStringAsFixed(0)}',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: primaryColor.withAlpha(100),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: primaryColor,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDays.length) {
                  if (sortedDays[index] % 7 == 0 || index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${sortedDays[index]}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedDays.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: cumulativeData,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withAlpha(180),
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                // Show dots at specific intervals
                if (index % 5 == 0 || index == cumulativeData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: primaryColor,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withAlpha(100),
                  primaryColor.withAlpha(20),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildSpendingCard(Currency currency) {
    final analytics = _currentAnalytics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Spending',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currency.formatAmount(analytics.totalSpending),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${analytics.transactionCount} transactions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(Currency currency) {
    final analytics = _currentAnalytics!;
    final isIncrease = analytics.isIncrease;
    final changeColor = isIncrease ? Colors.red : Colors.green;
    final changeIcon = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs Previous ${_selectedPeriod == 'weekly' ? 'Week' : _selectedPeriod == 'monthly' ? 'Month' : 'Year'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currency.formatAmount(analytics.previousPeriodSpending),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: changeColor.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, size: 16, color: changeColor),
                  const SizedBox(width: 4),
                  Text(
                    '${analytics.changePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.receipt_long,
                label: 'Transactions',
                value: _currentAnalytics?.transactionCount.toString() ?? '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                label: 'Period',
                value: _selectedPeriod == 'weekly'
                    ? 'This Week'
                    : _selectedPeriod == 'monthly'
                        ? 'This Month'
                        : 'This Year',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
