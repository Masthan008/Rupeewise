import '../services/supabase_service.dart';

/// Budget period types
enum BudgetPeriod { weekly, monthly, yearly }

/// Model class for budget data
class Budget {
  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };
  }
}

/// Service for managing budgets in Supabase
class BudgetService {
  final _client = SupabaseService.instance.client;

  /// Create a new budget
  Future<Budget> createBudget({
    required double amount,
    required BudgetPeriod period,
    String? categoryId,
    DateTime? startDate,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final start = startDate ?? DateTime.now();
    final end = _calculateEndDate(start, period);

    final response = await _client.from('budgets').insert({
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period.name,
      'start_date': start.toIso8601String().split('T')[0],
      'end_date': end.toIso8601String().split('T')[0],
    }).select().single();

    return Budget.fromJson(response);
  }

  /// Calculate end date based on period
  DateTime _calculateEndDate(DateTime start, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return start.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(start.year, start.month + 1, start.day);
      case BudgetPeriod.yearly:
        return DateTime(start.year + 1, start.month, start.day);
    }
  }

  /// Get all budgets for current user
  Future<List<Budget>> getBudgets() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Budget.fromJson(e)).toList();
  }

  /// Get active budgets (current period)
  Future<List<Budget>> getActiveBudgets() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .lte('start_date', today)
        .gte('end_date', today);

    return (response as List).map((e) => Budget.fromJson(e)).toList();
  }

  /// Check if budget is exceeded
  Future<bool> isBudgetExceeded(Budget budget, double currentSpending) async {
    return currentSpending >= budget.amount;
  }

  /// Get budget utilization percentage
  double getBudgetUtilization(Budget budget, double currentSpending) {
    if (budget.amount <= 0) return 0;
    return (currentSpending / budget.amount) * 100;
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('budgets')
        .delete()
        .eq('id', budgetId)
        .eq('user_id', userId);
  }

  /// Update a budget
  Future<Budget> updateBudget({
    required String budgetId,
    double? amount,
    BudgetPeriod? period,
    String? categoryId,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (amount != null) updates['amount'] = amount;
    if (period != null) updates['period'] = period.name;
    if (categoryId != null) updates['category_id'] = categoryId;

    final response = await _client
        .from('budgets')
        .update(updates)
        .eq('id', budgetId)
        .eq('user_id', userId)
        .select()
        .single();

    return Budget.fromJson(response);
  }
}
