import 'supabase_service.dart';

/// Income type categories
enum IncomeType {
  salary,
  freelance,
  investment,
  business,
  rental,
  gift,
  refund,
  other,
}

/// Income model
class Income {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final IncomeType type;
  final String? description;
  final DateTime incomeDate;
  final bool isRecurring;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    this.description,
    required this.incomeDate,
    required this.isRecurring,
    required this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      type: IncomeType.values.firstWhere(
        (t) => t.name == json['income_type'],
        orElse: () => IncomeType.other,
      ),
      description: json['description'] as String?,
      incomeDate: DateTime.parse(json['income_date'] as String),
      isRecurring: json['is_recurring'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'income_type': type.name,
      'description': description,
      'income_date': incomeDate.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
    };
  }

  /// Get display name for income type
  String get typeDisplayName {
    switch (type) {
      case IncomeType.salary:
        return 'Salary';
      case IncomeType.freelance:
        return 'Freelance';
      case IncomeType.investment:
        return 'Investment';
      case IncomeType.business:
        return 'Business';
      case IncomeType.rental:
        return 'Rental';
      case IncomeType.gift:
        return 'Gift';
      case IncomeType.refund:
        return 'Refund';
      case IncomeType.other:
        return 'Other';
    }
  }
}

/// Service for managing income entries
class IncomeService {
  final _client = SupabaseService.instance.client;

  /// Add new income entry
  Future<Income> addIncome({
    required double amount,
    required String currency,
    required IncomeType type,
    String? description,
    DateTime? incomeDate,
    bool isRecurring = false,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('income').insert({
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'income_type': type.name,
      'description': description,
      'income_date': (incomeDate ?? DateTime.now()).toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
    }).select().single();

    return Income.fromJson(response);
  }

  /// Get all income entries
  Future<List<Income>> getIncome() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('income')
        .select()
        .eq('user_id', userId)
        .order('income_date', ascending: false);

    return (response as List)
        .map((json) => Income.fromJson(json))
        .toList();
  }

  /// Get income for date range
  Future<List<Income>> getIncomeByDateRange(DateTime start, DateTime end) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final response = await _client
        .from('income')
        .select()
        .eq('user_id', userId)
        .gte('income_date', startStr)
        .lte('income_date', endStr)
        .order('income_date', ascending: false);

    return (response as List)
        .map((json) => Income.fromJson(json))
        .toList();
  }

  /// Get current month's total income
  Future<double> getCurrentMonthIncome() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final income = await getIncomeByDateRange(startOfMonth, now);
    
    double total = 0;
    for (final i in income) {
      total += i.amount;
    }
    return total;
  }

  /// Get income by type
  Future<Map<IncomeType, double>> getIncomeByType({DateTime? start, DateTime? end}) async {
    final now = DateTime.now();
    final income = await getIncomeByDateRange(
      start ?? DateTime(now.year, now.month, 1),
      end ?? now,
    );

    final byType = <IncomeType, double>{};
    for (final i in income) {
      byType[i.type] = (byType[i.type] ?? 0) + i.amount;
    }
    return byType;
  }

  /// Delete income entry
  Future<void> deleteIncome(String incomeId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('income')
        .delete()
        .eq('id', incomeId)
        .eq('user_id', userId);
  }

  /// Update income entry
  Future<Income> updateIncome({
    required String incomeId,
    double? amount,
    IncomeType? type,
    String? description,
    DateTime? incomeDate,
    bool? isRecurring,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (amount != null) updates['amount'] = amount;
    if (type != null) updates['income_type'] = type.name;
    if (description != null) updates['description'] = description;
    if (incomeDate != null) updates['income_date'] = incomeDate.toIso8601String().split('T')[0];
    if (isRecurring != null) updates['is_recurring'] = isRecurring;

    final response = await _client
        .from('income')
        .update(updates)
        .eq('id', incomeId)
        .eq('user_id', userId)
        .select()
        .single();

    return Income.fromJson(response);
  }

  /// Get net balance (income - expenses)
  Future<double> getNetBalance() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final income = await getCurrentMonthIncome();
    
    // Get expenses for current month - using Supabase directly
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return income;
    
    final startStr = startOfMonth.toIso8601String().split('T')[0];
    final endStr = now.toIso8601String().split('T')[0];
    
    final expenseResponse = await _client
        .from('expenses')
        .select('amount')
        .eq('user_id', userId)
        .gte('expense_date', startStr)
        .lte('expense_date', endStr);
    
    double expenses = 0;
    for (final e in (expenseResponse as List)) {
      expenses += (e['amount'] as num).toDouble();
    }
    
    return income - expenses;
  }
}
