import '../services/supabase_service.dart';

/// Model class for category data
class Category {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#4CAF50',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }
}

/// Default categories to seed for new users
class DefaultCategories {
  static const List<Map<String, String>> categories = [
    {'name': 'Food & Dining', 'icon': 'restaurant', 'color': '#FF5722'},
    {'name': 'Transportation', 'icon': 'directions_car', 'color': '#2196F3'},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '#9C27B0'},
    {'name': 'Entertainment', 'icon': 'movie', 'color': '#E91E63'},
    {'name': 'Bills & Utilities', 'icon': 'receipt', 'color': '#607D8B'},
    {'name': 'Healthcare', 'icon': 'medical_services', 'color': '#F44336'},
    {'name': 'Education', 'icon': 'school', 'color': '#3F51B5'},
    {'name': 'Travel', 'icon': 'flight', 'color': '#00BCD4'},
    {'name': 'Personal Care', 'icon': 'spa', 'color': '#FF9800'},
    {'name': 'Other', 'icon': 'more_horiz', 'color': '#795548'},
  ];
}

/// Service for managing categories in Supabase
class CategoryService {
  final _client = SupabaseService.instance.client;

  /// Create default categories for a new user
  Future<void> seedDefaultCategories() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check if user already has categories
    final existing = await _client
        .from('categories')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    if ((existing as List).isNotEmpty) return; // Categories already exist

    // Insert default categories
    final categories = DefaultCategories.categories.map((cat) => {
      'user_id': userId,
      'name': cat['name'],
      'icon': cat['icon'],
      'color': cat['color'],
      'is_default': true,
    }).toList();

    await _client.from('categories').insert(categories);
  }

  /// Get all categories for current user
  Future<List<Category>> getCategories() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('name');

    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  /// Add a new category
  Future<Category> addCategory({
    required String name,
    String icon = 'category',
    String color = '#4CAF50',
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('categories').insert({
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': false,
    }).select().single();

    return Category.fromJson(response);
  }

  /// Update a category
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;

    final response = await _client
        .from('categories')
        .update(updates)
        .eq('id', categoryId)
        .eq('user_id', userId)
        .select()
        .single();

    return Category.fromJson(response);
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', userId);
  }
}
