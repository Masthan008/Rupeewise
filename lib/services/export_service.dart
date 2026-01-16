import 'dart:convert';
import 'expense_service.dart';
import 'category_service.dart';
import 'supabase_service.dart';
import 'export_download_stub.dart'
    if (dart.library.html) 'export_download_web.dart' as download;

/// Export record model
class ExportRecord {
  final String id;
  final String userId;
  final String format;
  final int recordCount;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final DateTime createdAt;

  ExportRecord({
    required this.id,
    required this.userId,
    required this.format,
    required this.recordCount,
    this.dateRangeStart,
    this.dateRangeEnd,
    required this.createdAt,
  });

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      format: json['format'] as String,
      recordCount: json['record_count'] as int,
      dateRangeStart: json['date_range_start'] != null
          ? DateTime.parse(json['date_range_start'] as String)
          : null,
      dateRangeEnd: json['date_range_end'] != null
          ? DateTime.parse(json['date_range_end'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Service for exporting data to CSV/JSON with file download and metadata tracking
class ExportService {
  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();
  final _client = SupabaseService.instance.client;

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

  /// Download file (platform-agnostic)
  void downloadFile({
    required String content,
    required String filename,
    required String mimeType,
  }) {
    download.downloadFile(content: content, filename: filename, mimeType: mimeType);
  }

  /// Export and download file with metadata tracking
  Future<ExportResult> exportAndDownload({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Generate export content
    String content;
    String mimeType;
    
    if (format == 'csv') {
      content = await exportExpensesToCsv(startDate: startDate, endDate: endDate);
      mimeType = 'text/csv';
    } else {
      content = await exportExpensesToJson(startDate: startDate, endDate: endDate);
      mimeType = 'application/json';
    }

    // Count records
    final recordCount = _countRecords(content, format);

    // Generate filename
    final filename = generateExportFilename(
      format: format,
      startDate: startDate,
      endDate: endDate,
    );

    // Download file
    downloadFile(content: content, filename: filename, mimeType: mimeType);

    // Save export metadata to Supabase
    await saveExportMetadata(
      format: format,
      recordCount: recordCount,
      startDate: startDate,
      endDate: endDate,
    );

    return ExportResult(
      success: true,
      filename: filename,
      recordCount: recordCount,
      content: content,
    );
  }

  /// Count records in export
  int _countRecords(String content, String format) {
    if (format == 'csv') {
      // Count lines minus header
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).length;
      return lines > 0 ? lines - 1 : 0;
    } else {
      // Parse JSON and count expenses
      try {
        final data = json.decode(content);
        return data['total_expenses'] ?? 0;
      } catch (_) {
        return 0;
      }
    }
  }

  /// Save export metadata to Supabase for admin auditing
  Future<void> saveExportMetadata({
    required String format,
    required int recordCount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('exports').insert({
      'user_id': userId,
      'format': format,
      'record_count': recordCount,
      'date_range_start': startDate?.toIso8601String().split('T')[0],
      'date_range_end': endDate?.toIso8601String().split('T')[0],
    });
  }

  /// Get user's export history
  Future<List<ExportRecord>> getExportHistory() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('exports')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => ExportRecord.fromJson(json))
        .toList();
  }
}

/// Result of export operation
class ExportResult {
  final bool success;
  final String filename;
  final int recordCount;
  final String content;
  final String? error;

  ExportResult({
    required this.success,
    required this.filename,
    required this.recordCount,
    required this.content,
    this.error,
  });
}
