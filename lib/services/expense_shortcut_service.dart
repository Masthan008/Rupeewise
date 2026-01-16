import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'expense_service.dart';

/// Quick expense shortcut model
class ExpenseShortcut {
  final String id;
  final String name;
  final double amount;
  final String? categoryId;
  final String? icon;
  final int usageCount;

  ExpenseShortcut({
    required this.id,
    required this.name,
    required this.amount,
    this.categoryId,
    this.icon,
    this.usageCount = 0,
  });

  factory ExpenseShortcut.fromJson(Map<String, dynamic> json) {
    return ExpenseShortcut(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String?,
      icon: json['icon'] as String?,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'icon': icon,
      'usageCount': usageCount,
    };
  }

  ExpenseShortcut copyWith({
    String? name,
    double? amount,
    String? categoryId,
    String? icon,
    int? usageCount,
  }) {
    return ExpenseShortcut(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

/// Service for managing quick expense shortcuts
class ExpenseShortcutService {
  static const String _storageKey = 'expense_shortcuts';
  final ExpenseService _expenseService = ExpenseService();

  /// Get all shortcuts (sorted by usage)
  Future<List<ExpenseShortcut>> getShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return _getDefaultShortcuts();

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      final shortcuts = jsonList
          .map((j) => ExpenseShortcut.fromJson(j as Map<String, dynamic>))
          .toList();
      
      // Sort by usage count (most used first)
      shortcuts.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      return shortcuts;
    } catch (_) {
      return _getDefaultShortcuts();
    }
  }

  /// Add a new shortcut
  Future<void> addShortcut(ExpenseShortcut shortcut) async {
    final shortcuts = await getShortcuts();
    shortcuts.add(shortcut);
    await _saveShortcuts(shortcuts);
  }

  /// Delete a shortcut
  Future<void> deleteShortcut(String id) async {
    final shortcuts = await getShortcuts();
    shortcuts.removeWhere((s) => s.id == id);
    await _saveShortcuts(shortcuts);
  }

  /// Use a shortcut (creates expense and increments usage)
  Future<Expense> useShortcut(ExpenseShortcut shortcut, String currency) async {
    // Create the expense
    final expense = await _expenseService.addExpense(
      amount: shortcut.amount,
      currency: currency,
      description: shortcut.name,
      categoryId: shortcut.categoryId,
      expenseDate: DateTime.now(),
    );

    // Increment usage count
    final shortcuts = await getShortcuts();
    final index = shortcuts.indexWhere((s) => s.id == shortcut.id);
    if (index != -1) {
      shortcuts[index] = shortcuts[index].copyWith(
        usageCount: shortcuts[index].usageCount + 1,
      );
      await _saveShortcuts(shortcuts);
    }

    return expense;
  }

  /// Update a shortcut
  Future<void> updateShortcut(ExpenseShortcut shortcut) async {
    final shortcuts = await getShortcuts();
    final index = shortcuts.indexWhere((s) => s.id == shortcut.id);
    if (index != -1) {
      shortcuts[index] = shortcut;
      await _saveShortcuts(shortcuts);
    }
  }

  /// Save shortcuts to storage
  Future<void> _saveShortcuts(List<ExpenseShortcut> shortcuts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(shortcuts.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Get default shortcuts
  List<ExpenseShortcut> _getDefaultShortcuts() {
    return [
      ExpenseShortcut(
        id: 'coffee',
        name: 'Coffee',
        amount: 50,
        icon: 'coffee',
      ),
      ExpenseShortcut(
        id: 'lunch',
        name: 'Lunch',
        amount: 150,
        icon: 'restaurant',
      ),
      ExpenseShortcut(
        id: 'auto',
        name: 'Auto/Cab',
        amount: 100,
        icon: 'local_taxi',
      ),
      ExpenseShortcut(
        id: 'snacks',
        name: 'Snacks',
        amount: 30,
        icon: 'fastfood',
      ),
    ];
  }

  /// Create custom shortcut
  ExpenseShortcut createShortcut({
    required String name,
    required double amount,
    String? categoryId,
    String? icon,
  }) {
    return ExpenseShortcut(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      categoryId: categoryId,
      icon: icon,
    );
  }

  /// Reset to default shortcuts
  Future<void> resetToDefaults() async {
    await _saveShortcuts(_getDefaultShortcuts());
  }
}
