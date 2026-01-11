import '../services/supabase_service.dart';

/// Model class for expense data
class Expense {
  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final String currency;
  final String? description;
  final DateTime expenseDate;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.currency,
    this.description,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      description: json['description'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
    };
  }
}

/// Service for managing expenses in Supabase
class ExpenseService {
  final _client = SupabaseService.instance.client;

  /// Add a new expense
  Future<Expense> addExpense({
    required double amount,
    required String currency,
    String? description,
    String? categoryId,
    DateTime? expenseDate,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('expenses').insert({
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'category_id': categoryId,
      'expense_date': (expenseDate ?? DateTime.now()).toIso8601String().split('T')[0],
    }).select().single();

    return Expense.fromJson(response);
  }

  /// Get all expenses for current user
  Future<List<Expense>> getExpenses() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('expense_date', ascending: false);

    return (response as List).map((e) => Expense.fromJson(e)).toList();
  }

  /// Get expenses for a date range
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .gte('expense_date', start.toIso8601String().split('T')[0])
        .lte('expense_date', end.toIso8601String().split('T')[0])
        .order('expense_date', ascending: false);

    return (response as List).map((e) => Expense.fromJson(e)).toList();
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('expenses')
        .delete()
        .eq('id', expenseId)
        .eq('user_id', userId);
  }

  /// Update an expense
  Future<Expense> updateExpense({
    required String expenseId,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? expenseDate,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (amount != null) updates['amount'] = amount;
    if (description != null) updates['description'] = description;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (expenseDate != null) {
      updates['expense_date'] = expenseDate.toIso8601String().split('T')[0];
    }
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('expenses')
        .update(updates)
        .eq('id', expenseId)
        .eq('user_id', userId)
        .select()
        .single();

    return Expense.fromJson(response);
  }

  /// Get total expenses for current month
  Future<double> getCurrentMonthTotal() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final expenses = await getExpensesByDateRange(startOfMonth, endOfMonth);
    double total = 0.0;
    for (final expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  /// Subscribe to real-time expense updates
  Stream<List<Map<String, dynamic>>> subscribeToExpenses() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }
}
