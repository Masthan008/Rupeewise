import 'supabase_service.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import 'savings_goal_service.dart';

/// Financial Health Score model
class HealthScore {
  final String id;
  final String userId;
  final int score;
  final int budgetScore;
  final int savingsScore;
  final int consistencyScore;
  final String month;
  final DateTime createdAt;

  HealthScore({
    required this.id,
    required this.userId,
    required this.score,
    required this.budgetScore,
    required this.savingsScore,
    required this.consistencyScore,
    required this.month,
    required this.createdAt,
  });

  factory HealthScore.fromJson(Map<String, dynamic> json) {
    return HealthScore(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      score: json['score'] as int,
      budgetScore: json['budget_score'] as int? ?? 0,
      savingsScore: json['savings_score'] as int? ?? 0,
      consistencyScore: json['consistency_score'] as int? ?? 0,
      month: json['month'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Get score grade (A, B, C, D, F)
  String get grade {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Get score description
  String get description {
    if (score >= 90) return 'Excellent! You\'re a financial superstar.';
    if (score >= 80) return 'Great job! Keep up the good work.';
    if (score >= 70) return 'Good progress. Room for improvement.';
    if (score >= 60) return 'Fair. Consider tightening your budget.';
    return 'Needs attention. Review your spending habits.';
  }
}

/// Service for calculating and storing financial health scores
class HealthScoreService {
  final _client = SupabaseService.instance.client;
  final ExpenseService _expenseService = ExpenseService();
  final BudgetService _budgetService = BudgetService();
  final SavingsGoalService _savingsService = SavingsGoalService();

  /// Calculate and store current month's health score
  Future<HealthScore> calculateAndSaveScore() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Calculate component scores
    final budgetScore = await _calculateBudgetScore();
    final savingsScore = await _calculateSavingsScore();
    final consistencyScore = await _calculateConsistencyScore();

    // Weighted average (budget 40%, savings 30%, consistency 30%)
    final totalScore = ((budgetScore * 0.4) + (savingsScore * 0.3) + (consistencyScore * 0.3)).round();

    // Upsert score for this month
    final response = await _client.from('health_scores').upsert({
      'user_id': userId,
      'score': totalScore,
      'budget_score': budgetScore,
      'savings_score': savingsScore,
      'consistency_score': consistencyScore,
      'month': month,
    }, onConflict: 'user_id,month').select().single();

    return HealthScore.fromJson(response);
  }

  /// Calculate budget adherence score (0-100)
  Future<int> _calculateBudgetScore() async {
    try {
      final budgets = await _budgetService.getBudgets();
      if (budgets.isEmpty) return 70; // No budgets = neutral score

      // Get all expenses for current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final expenses = await _expenseService.getExpensesByDateRange(startOfMonth, now);

      int totalScore = 0;
      for (final budget in budgets) {
        // Calculate spent for this budget's category
        double spent = 0;
        if (budget.categoryId != null) {
          spent = expenses
              .where((e) => e.categoryId == budget.categoryId)
              .fold(0.0, (sum, e) => sum + e.amount);
        } else {
          // Total budget (all categories)
          spent = expenses.fold(0.0, (sum, e) => sum + e.amount);
        }

        final ratio = budget.amount > 0 ? spent / budget.amount : 1.0;

        if (ratio <= 0.8) {
          totalScore += 100; // Under 80% = excellent
        } else if (ratio <= 1.0) {
          totalScore += 80; // 80-100% = good
        } else if (ratio <= 1.2) {
          totalScore += 50; // 100-120% = fair
        } else {
          totalScore += 20; // Over 120% = poor
        }
      }

      return (totalScore / budgets.length).round();
    } catch (_) {
      return 70;
    }
  }

  /// Calculate savings score (0-100)
  Future<int> _calculateSavingsScore() async {
    try {
      final goals = await _savingsService.getGoals();
      if (goals.isEmpty) return 50; // No goals = neutral

      int totalScore = 0;
      for (final goal in goals) {
        final progress = goal.progressPercentage;
        
        if (goal.isCompleted) {
          totalScore += 100;
        } else if (progress >= 75) {
          totalScore += 90;
        } else if (progress >= 50) {
          totalScore += 70;
        } else if (progress >= 25) {
          totalScore += 50;
        } else {
          totalScore += 30;
        }
      }

      return (totalScore / goals.length).round();
    } catch (_) {
      return 50;
    }
  }

  /// Calculate expense tracking consistency score (0-100)
  Future<int> _calculateConsistencyScore() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final expenses = await _expenseService.getExpensesByDateRange(startOfMonth, now);

      if (expenses.isEmpty) return 30; // No expenses tracked = poor

      // Check how many days have expenses
      final daysWithExpenses = <int>{};
      for (final expense in expenses) {
        daysWithExpenses.add(expense.expenseDate.day);
      }

      final daysPassed = now.day;
      final coverageRatio = daysWithExpenses.length / daysPassed;

      if (coverageRatio >= 0.7) return 100; // 70%+ days tracked
      if (coverageRatio >= 0.5) return 80;
      if (coverageRatio >= 0.3) return 60;
      if (coverageRatio >= 0.1) return 40;
      return 20;
    } catch (_) {
      return 50;
    }
  }

  /// Get current month's health score
  Future<HealthScore?> getCurrentScore() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      final response = await _client
          .from('health_scores')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .single();

      return HealthScore.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Get health score history (last 6 months)
  Future<List<HealthScore>> getScoreHistory() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('health_scores')
          .select()
          .eq('user_id', userId)
          .order('month', ascending: false)
          .limit(6);

      return (response as List)
          .map((json) => HealthScore.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get or calculate current score
  Future<HealthScore> getOrCalculateScore() async {
    final existing = await getCurrentScore();
    if (existing != null) return existing;
    return calculateAndSaveScore();
  }
}
