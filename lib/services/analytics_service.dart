import 'expense_service.dart';

/// Analytics data for a specific period
class PeriodAnalytics {
  final double totalSpending;
  final double previousPeriodSpending;
  final double changePercentage;
  final bool isIncrease;
  final int transactionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  PeriodAnalytics({
    required this.totalSpending,
    required this.previousPeriodSpending,
    required this.changePercentage,
    required this.isIncrease,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
  });
}

/// Analytics service for expense data analysis
class AnalyticsService {
  final ExpenseService _expenseService = ExpenseService();

  /// Get weekly analytics (current week vs previous week)
  Future<PeriodAnalytics> getWeeklyAnalytics() async {
    final now = DateTime.now();
    
    // Current week (Sunday to Saturday)
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

    // Previous week
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = currentWeekStart.subtract(const Duration(days: 1));

    return _calculatePeriodAnalytics(
      currentStart: DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day),
      currentEnd: DateTime(currentWeekEnd.year, currentWeekEnd.month, currentWeekEnd.day),
      previousStart: DateTime(previousWeekStart.year, previousWeekStart.month, previousWeekStart.day),
      previousEnd: DateTime(previousWeekEnd.year, previousWeekEnd.month, previousWeekEnd.day),
    );
  }

  /// Get monthly analytics (current month vs previous month)
  Future<PeriodAnalytics> getMonthlyAnalytics() async {
    final now = DateTime.now();
    
    // Current month
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

    // Previous month
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd = DateTime(now.year, now.month, 0);

    return _calculatePeriodAnalytics(
      currentStart: currentMonthStart,
      currentEnd: currentMonthEnd,
      previousStart: previousMonthStart,
      previousEnd: previousMonthEnd,
    );
  }

  /// Get yearly analytics (current year vs previous year)
  Future<PeriodAnalytics> getYearlyAnalytics() async {
    final now = DateTime.now();
    
    // Current year
    final currentYearStart = DateTime(now.year, 1, 1);
    final currentYearEnd = DateTime(now.year, 12, 31);

    // Previous year
    final previousYearStart = DateTime(now.year - 1, 1, 1);
    final previousYearEnd = DateTime(now.year - 1, 12, 31);

    return _calculatePeriodAnalytics(
      currentStart: currentYearStart,
      currentEnd: currentYearEnd,
      previousStart: previousYearStart,
      previousEnd: previousYearEnd,
    );
  }

  /// Calculate analytics for given periods
  Future<PeriodAnalytics> _calculatePeriodAnalytics({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) async {
    // Get expenses for both periods
    final currentExpenses = await _expenseService.getExpensesByDateRange(
      currentStart,
      currentEnd,
    );
    final previousExpenses = await _expenseService.getExpensesByDateRange(
      previousStart,
      previousEnd,
    );

    // Calculate totals
    double currentTotal = 0;
    for (final expense in currentExpenses) {
      currentTotal += expense.amount;
    }

    double previousTotal = 0;
    for (final expense in previousExpenses) {
      previousTotal += expense.amount;
    }

    // Calculate change percentage
    double changePercentage = 0;
    if (previousTotal > 0) {
      changePercentage = ((currentTotal - previousTotal) / previousTotal) * 100;
    } else if (currentTotal > 0) {
      changePercentage = 100;
    }

    return PeriodAnalytics(
      totalSpending: currentTotal,
      previousPeriodSpending: previousTotal,
      changePercentage: changePercentage.abs(),
      isIncrease: currentTotal > previousTotal,
      transactionCount: currentExpenses.length,
      periodStart: currentStart,
      periodEnd: currentEnd,
    );
  }

  /// Get spending by category for a date range
  Future<Map<String, double>> getSpendingByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await _expenseService.getExpensesByDateRange(start, end);
    
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      final categoryId = expense.categoryId ?? 'uncategorized';
      categorySpending[categoryId] = (categorySpending[categoryId] ?? 0) + expense.amount;
    }
    
    return categorySpending;
  }

  /// Get daily spending for the current month
  Future<Map<int, double>> getDailySpendingForMonth() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final expenses = await _expenseService.getExpensesByDateRange(monthStart, monthEnd);
    
    final dailySpending = <int, double>{};
    for (final expense in expenses) {
      final day = expense.expenseDate.day;
      dailySpending[day] = (dailySpending[day] ?? 0) + expense.amount;
    }
    
    return dailySpending;
  }
}
