/// Utility functions for RupeeWise
library;

/// Date formatting utilities
class DateUtils {
  /// Format date as readable string (e.g., "Jan 10, 2026")
  static String formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Currency formatting utilities
class CurrencyUtils {
  /// Format amount with currency symbol
  static String format(double amount, {String symbol = '₹'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
