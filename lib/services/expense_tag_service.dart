import 'supabase_service.dart';

/// Expense tag model
class ExpenseTag {
  final String id;
  final String userId;
  final String name;
  final String color;
  final DateTime createdAt;

  ExpenseTag({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory ExpenseTag.fromJson(Map<String, dynamic> json) {
    return ExpenseTag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6366F1',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Service for managing expense tags
class ExpenseTagService {
  final _client = SupabaseService.instance.client;

  /// Get all tags for current user
  Future<List<ExpenseTag>> getTags() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('expense_tags')
          .select()
          .eq('user_id', userId)
          .order('name');

      return (response as List)
          .map((json) => ExpenseTag.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Create a new tag
  Future<ExpenseTag> createTag({
    required String name,
    String color = '#6366F1',
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('expense_tags').insert({
      'user_id': userId,
      'name': name,
      'color': color,
    }).select().single();

    return ExpenseTag.fromJson(response);
  }

  /// Delete a tag
  Future<void> deleteTag(String tagId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('expense_tags')
        .delete()
        .eq('id', tagId)
        .eq('user_id', userId);
  }

  /// Add tag to expense
  Future<void> addTagToExpense(String expenseId, String tagId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('expense_tag_links').insert({
      'expense_id': expenseId,
      'tag_id': tagId,
    });
  }

  /// Remove tag from expense
  Future<void> removeTagFromExpense(String expenseId, String tagId) async {
    await _client
        .from('expense_tag_links')
        .delete()
        .eq('expense_id', expenseId)
        .eq('tag_id', tagId);
  }

  /// Get tags for an expense
  Future<List<ExpenseTag>> getTagsForExpense(String expenseId) async {
    try {
      final response = await _client
          .from('expense_tag_links')
          .select('tag_id, expense_tags(*)')
          .eq('expense_id', expenseId);

      return (response as List)
          .map((json) => ExpenseTag.fromJson(json['expense_tags']))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get expenses by tag
  Future<List<String>> getExpenseIdsByTag(String tagId) async {
    try {
      final response = await _client
          .from('expense_tag_links')
          .select('expense_id')
          .eq('tag_id', tagId);

      return (response as List)
          .map((json) => json['expense_id'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Suggested tag colors
  static List<String> get suggestedColors => [
    '#EF4444', // Red
    '#F97316', // Orange
    '#EAB308', // Yellow
    '#22C55E', // Green
    '#14B8A6', // Teal
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
  ];
}
