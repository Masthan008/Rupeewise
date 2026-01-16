import 'supabase_service.dart';
import 'notification_service.dart';
import 'expense_service.dart';

/// Daily spending limit model
class SpendingLimit {
  final String id;
  final String userId;
  final double dailyLimit;
  final double weeklyLimit;
  final double monthlyLimit;
  final int alertThreshold; // Percentage (e.g., 80 = alert at 80%)
  final bool alertsEnabled;
  final DateTime createdAt;

  SpendingLimit({
    required this.id,
    required this.userId,
    required this.dailyLimit,
    required this.weeklyLimit,
    required this.monthlyLimit,
    required this.alertThreshold,
    required this.alertsEnabled,
    required this.createdAt,
  });

  factory SpendingLimit.fromJson(Map<String, dynamic> json) {
    return SpendingLimit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyLimit: (json['daily_limit'] as num?)?.toDouble() ?? 0,
      weeklyLimit: (json['weekly_limit'] as num?)?.toDouble() ?? 0,
      monthlyLimit: (json['monthly_limit'] as num?)?.toDouble() ?? 0,
      alertThreshold: json['alert_threshold'] as int? ?? 80,
      alertsEnabled: json['alerts_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit': dailyLimit,
      'weekly_limit': weeklyLimit,
      'monthly_limit': monthlyLimit,
      'alert_threshold': alertThreshold,
      'alerts_enabled': alertsEnabled,
    };
  }
}

/// Spending status for a period
class SpendingStatus {
  final double limit;
  final double spent;
  final String period; // 'daily', 'weekly', 'monthly'

  SpendingStatus({
    required this.limit,
    required this.spent,
    required this.period,
  });

  double get percentUsed => limit > 0 ? (spent / limit) * 100 : 0;
  double get remaining => (limit - spent).clamp(0, double.infinity);
  bool get isExceeded => spent >= limit;
  bool get isNearLimit => percentUsed >= 80 && !isExceeded;
}

/// Service for managing spending limits and alerts
class SpendingLimitService {
  final _client = SupabaseService.instance.client;
  final NotificationService _notificationService = NotificationService();
  final ExpenseService _expenseService = ExpenseService();

  /// Get user's spending limits
  Future<SpendingLimit?> getSpendingLimits() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('spending_limits')
          .select()
          .eq('user_id', userId)
          .single();

      return SpendingLimit.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Save or update spending limits
  Future<SpendingLimit> saveSpendingLimits({
    double? dailyLimit,
    double? weeklyLimit,
    double? monthlyLimit,
    int? alertThreshold,
    bool? alertsEnabled,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = <String, dynamic>{
      'user_id': userId,
    };
    if (dailyLimit != null) data['daily_limit'] = dailyLimit;
    if (weeklyLimit != null) data['weekly_limit'] = weeklyLimit;
    if (monthlyLimit != null) data['monthly_limit'] = monthlyLimit;
    if (alertThreshold != null) data['alert_threshold'] = alertThreshold;
    if (alertsEnabled != null) data['alerts_enabled'] = alertsEnabled;

    final response = await _client
        .from('spending_limits')
        .upsert(data, onConflict: 'user_id')
        .select()
        .single();

    return SpendingLimit.fromJson(response);
  }

  /// Get current spending status for all periods
  Future<Map<String, SpendingStatus>> getSpendingStatus() async {
    final limits = await getSpendingLimits();
    if (limits == null) return {};

    final now = DateTime.now();
    
    // Calculate period starts
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Get expenses for each period
    final dailyExpenses = await _expenseService.getExpensesByDateRange(dayStart, now);
    final weeklyExpenses = await _expenseService.getExpensesByDateRange(weekStart, now);
    final monthlyExpenses = await _expenseService.getExpensesByDateRange(monthStart, now);

    // Calculate totals
    final dailySpent = dailyExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final weeklySpent = weeklyExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final monthlySpent = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return {
      'daily': SpendingStatus(
        limit: limits.dailyLimit,
        spent: dailySpent,
        period: 'daily',
      ),
      'weekly': SpendingStatus(
        limit: limits.weeklyLimit,
        spent: weeklySpent,
        period: 'weekly',
      ),
      'monthly': SpendingStatus(
        limit: limits.monthlyLimit,
        spent: monthlySpent,
        period: 'monthly',
      ),
    };
  }

  /// Check limits and send alerts if needed
  Future<void> checkAndSendAlerts() async {
    final limits = await getSpendingLimits();
    if (limits == null || !limits.alertsEnabled) return;

    final status = await getSpendingStatus();

    for (final entry in status.entries) {
      final s = entry.value;
      if (s.limit <= 0) continue;

      if (s.isExceeded) {
        await _sendAlert(
          title: '${_capitalize(s.period)} Limit Exceeded!',
          message: 'You\'ve spent more than your ${s.period} limit.',
          type: NotificationType.alert,
        );
      } else if (s.percentUsed >= limits.alertThreshold) {
        await _sendAlert(
          title: '${_capitalize(s.period)} Limit Warning',
          message: 'You\'ve used ${s.percentUsed.toStringAsFixed(0)}% of your ${s.period} limit.',
          type: NotificationType.warning,
        );
      }
    }
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Future<void> _sendAlert({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      await _notificationService.createNotification(
        title: title,
        message: message,
        type: type,
      );
    } catch (_) {
      // Silently fail
    }
  }

  /// Get daily remaining budget
  Future<double> getDailyRemaining() async {
    final status = await getSpendingStatus();
    return status['daily']?.remaining ?? 0;
  }

  /// Check if user has any limits set
  Future<bool> hasLimitsConfigured() async {
    final limits = await getSpendingLimits();
    if (limits == null) return false;
    return limits.dailyLimit > 0 || limits.weeklyLimit > 0 || limits.monthlyLimit > 0;
  }
}
