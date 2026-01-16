import 'supabase_service.dart';
import 'expense_service.dart';

/// Recurrence frequency enum
enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

/// Recurring expense model
class RecurringExpense {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String? categoryId;
  final String? description;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastExecutedAt;
  final DateTime? nextExecutionDate;
  final bool isActive;
  final DateTime createdAt;

  RecurringExpense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastExecutedAt,
    this.nextExecutionDate,
    required this.isActive,
    required this.createdAt,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      categoryId: json['category_id'] as String?,
      description: json['description'] as String?,
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      lastExecutedAt: json['last_executed_at'] != null
          ? DateTime.parse(json['last_executed_at'] as String)
          : null,
      nextExecutionDate: json['next_execution_date'] != null
          ? DateTime.parse(json['next_execution_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Get frequency display name
  String get frequencyDisplayName {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Bi-weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }
}

/// Service for managing recurring expenses
class RecurringExpenseService {
  final _client = SupabaseService.instance.client;
  final ExpenseService _expenseService = ExpenseService();

  /// Get all recurring expenses for current user
  Future<List<RecurringExpense>> getRecurringExpenses() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => RecurringExpense.fromJson(json))
        .toList();
  }

  /// Get active recurring expenses
  Future<List<RecurringExpense>> getActiveRecurringExpenses() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('next_execution_date', ascending: true);

    return (response as List)
        .map((json) => RecurringExpense.fromJson(json))
        .toList();
  }

  /// Create a new recurring expense
  Future<RecurringExpense> createRecurringExpense({
    required double amount,
    required String currency,
    String? categoryId,
    String? description,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final nextExecution = _calculateNextExecution(startDate, frequency);

    final response = await _client
        .from('recurring_expenses')
        .insert({
          'user_id': userId,
          'amount': amount,
          'currency': currency,
          'category_id': categoryId,
          'description': description,
          'frequency': frequency.name,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate?.toIso8601String().split('T')[0],
          'next_execution_date': nextExecution.toIso8601String().split('T')[0],
          'is_active': true,
        })
        .select()
        .single();

    return RecurringExpense.fromJson(response);
  }

  /// Pause/Resume recurring expense
  Future<RecurringExpense> toggleActive(String id) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get current state
    final current = await _client
        .from('recurring_expenses')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .single();

    final isActive = !(current['is_active'] as bool);

    final response = await _client
        .from('recurring_expenses')
        .update({'is_active': isActive})
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return RecurringExpense.fromJson(response);
  }

  /// Delete recurring expense
  Future<void> deleteRecurringExpense(String id) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('recurring_expenses')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Process due recurring expenses and create actual expenses
  Future<int> processDueExpenses() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return 0;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    // Get due recurring expenses
    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .lte('next_execution_date', todayStr);

    final dueExpenses = (response as List)
        .map((json) => RecurringExpense.fromJson(json))
        .toList();

    int processed = 0;

    for (final recurring in dueExpenses) {
      // Check if end date passed
      if (recurring.endDate != null && recurring.endDate!.isBefore(today)) {
        // Deactivate this recurring expense
        await _client
            .from('recurring_expenses')
            .update({'is_active': false})
            .eq('id', recurring.id);
        continue;
      }

      // Create the actual expense
      await _expenseService.addExpense(
        amount: recurring.amount,
        currency: recurring.currency,
        categoryId: recurring.categoryId,
        description: '${recurring.description ?? 'Recurring expense'} (Auto)',
        expenseDate: today,
      );

      // Calculate next execution date
      final nextExecution = _calculateNextExecution(today, recurring.frequency);

      // Update recurring expense
      await _client.from('recurring_expenses').update({
        'last_executed_at': today.toIso8601String(),
        'next_execution_date': nextExecution.toIso8601String().split('T')[0],
      }).eq('id', recurring.id);

      processed++;
    }

    return processed;
  }

  /// Calculate next execution date based on frequency
  DateTime _calculateNextExecution(DateTime from, RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceFrequency.quarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}
