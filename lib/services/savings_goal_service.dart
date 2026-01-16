import 'supabase_service.dart';

/// Savings goal model
class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    this.description,
    required this.isCompleted,
    required this.createdAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(json['target_date'] as String),
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String().split('T')[0],
      'description': description,
      'is_completed': isCompleted,
    };
  }

  /// Calculate progress percentage (0-100)
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0, 100);
  }

  /// Calculate remaining amount
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  /// Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  /// Check if goal is overdue
  bool get isOverdue {
    return !isCompleted && daysRemaining < 0;
  }

  /// Copy with new values
  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? description,
    bool? isCompleted,
  }) {
    return SavingsGoal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

/// Service for managing savings goals
class SavingsGoalService {
  final _client = SupabaseService.instance.client;

  /// Get all savings goals for current user
  Future<List<SavingsGoal>> getGoals() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('savings_goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SavingsGoal.fromJson(json))
        .toList();
  }

  /// Get active (non-completed) savings goals
  Future<List<SavingsGoal>> getActiveGoals() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('savings_goals')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('target_date', ascending: true);

    return (response as List)
        .map((json) => SavingsGoal.fromJson(json))
        .toList();
  }

  /// Create a new savings goal
  Future<SavingsGoal> createGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    String? description,
    double currentAmount = 0,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('savings_goals')
        .insert({
          'user_id': userId,
          'name': name,
          'target_amount': targetAmount,
          'current_amount': currentAmount,
          'target_date': targetDate.toIso8601String().split('T')[0],
          'description': description,
          'is_completed': false,
        })
        .select()
        .single();

    return SavingsGoal.fromJson(response);
  }

  /// Update savings goal
  Future<SavingsGoal> updateGoal({
    required String goalId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? description,
    bool? isCompleted,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (targetAmount != null) updates['target_amount'] = targetAmount;
    if (currentAmount != null) updates['current_amount'] = currentAmount;
    if (targetDate != null) {
      updates['target_date'] = targetDate.toIso8601String().split('T')[0];
    }
    if (description != null) updates['description'] = description;
    if (isCompleted != null) updates['is_completed'] = isCompleted;

    final response = await _client
        .from('savings_goals')
        .update(updates)
        .eq('id', goalId)
        .eq('user_id', userId)
        .select()
        .single();

    return SavingsGoal.fromJson(response);
  }

  /// Add amount to savings goal
  Future<SavingsGoal> addToGoal({
    required String goalId,
    required double amount,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get current goal
    final currentResponse = await _client
        .from('savings_goals')
        .select()
        .eq('id', goalId)
        .eq('user_id', userId)
        .single();

    final current = SavingsGoal.fromJson(currentResponse);
    final newAmount = current.currentAmount + amount;
    final isCompleted = newAmount >= current.targetAmount;

    return updateGoal(
      goalId: goalId,
      currentAmount: newAmount,
      isCompleted: isCompleted,
    );
  }

  /// Delete savings goal
  Future<void> deleteGoal(String goalId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('savings_goals')
        .delete()
        .eq('id', goalId)
        .eq('user_id', userId);
  }

  /// Get total savings across all goals
  Future<double> getTotalSavings() async {
    final goals = await getGoals();
    double total = 0.0;
    for (final goal in goals) {
      total += goal.currentAmount;
    }
    return total;
  }

  /// Get savings goal by ID
  Future<SavingsGoal?> getGoalById(String goalId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('savings_goals')
          .select()
          .eq('id', goalId)
          .eq('user_id', userId)
          .single();

      return SavingsGoal.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
