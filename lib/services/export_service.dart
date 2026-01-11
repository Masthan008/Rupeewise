import 'dart:convert';
import 'expense_service.dart';
import 'category_service.dart';

/// Service for exporting data to CSV
class ExportService {
  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();

  /// Export expenses to CSV string for a date range
  Future<String> exportExpensesToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Expense> expenses;

    if (startDate != null && endDate != null) {
      expenses = await _expenseService.getExpensesByDateRange(startDate, endDate);
    } else {
      expenses = await _expenseService.getExpenses();
    }

    // Get categories for lookup
    final categories = await _categoryService.getCategories();
    final categoryMap = {for (var c in categories) c.id: c.name};

    // Build CSV
    final buffer = StringBuffer();

    // Header row
    buffer.writeln('Date,Amount,Currency,Category,Description');

    // Data rows
    for (final expense in expenses) {
      final date = expense.expenseDate.toIso8601String().split('T')[0];
      final amount = expense.amount.toStringAsFixed(2);
      final currency = expense.currency;
      final category = categoryMap[expense.categoryId] ?? 'Uncategorized';
      final description = _escapeCsvField(expense.description ?? '');

      buffer.writeln('$date,$amount,$currency,$category,$description');
    }

    return buffer.toString();
  }

  /// Escape special characters in CSV fields
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Export expenses as JSON string for a date range
  Future<String> exportExpensesToJson({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Expense> expenses;

    if (startDate != null && endDate != null) {
      expenses = await _expenseService.getExpensesByDateRange(startDate, endDate);
    } else {
      expenses = await _expenseService.getExpenses();
    }

    // Get categories for lookup
    final categories = await _categoryService.getCategories();
    final categoryMap = {for (var c in categories) c.id: c.name};

    // Build JSON data
    final data = expenses.map((expense) => {
      'date': expense.expenseDate.toIso8601String().split('T')[0],
      'amount': expense.amount,
      'currency': expense.currency,
      'category': categoryMap[expense.categoryId] ?? 'Uncategorized',
      'description': expense.description ?? '',
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toIso8601String(),
      'total_expenses': expenses.length,
      'expenses': data,
    });
  }

  /// Get export data as bytes for file download
  List<int> getExportBytes(String content) {
    return utf8.encode(content);
  }

  /// Generate filename for export
  String generateExportFilename({
    String format = 'csv',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    if (startDate != null && endDate != null) {
      final start = startDate.toIso8601String().split('T')[0];
      final end = endDate.toIso8601String().split('T')[0];
      return 'rupeewise_expenses_${start}_to_$end.$format';
    }
    return 'rupeewise_expenses_$timestamp.$format';
  }
}
