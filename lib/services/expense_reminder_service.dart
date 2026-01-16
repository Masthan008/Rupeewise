import 'package:shared_preferences/shared_preferences.dart';
import 'expense_service.dart';
import 'notification_service.dart';

/// Service for smart expense reminders
/// Reminds users to add expenses if inactive for 2 or 7 days
class ExpenseReminderService {
  static const String _lastExpenseKey = 'last_expense_date';
  static const String _lastReminderKey = 'last_reminder_date';
  
  final ExpenseService _expenseService = ExpenseService();
  final NotificationService _notificationService = NotificationService();

  /// Check and send reminders if needed
  Future<void> checkAndSendReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    // Get last reminder date to avoid spamming
    final lastReminderStr = prefs.getString(_lastReminderKey);
    if (lastReminderStr == todayStr) {
      // Already sent reminder today
      return;
    }

    // Get last expense date from local storage or fetch from expenses
    String? lastExpenseStr = prefs.getString(_lastExpenseKey);
    
    if (lastExpenseStr == null) {
      // Try to get from actual expenses
      final expenses = await _expenseService.getExpenses();
      if (expenses.isNotEmpty) {
        final latestDate = expenses
            .map((e) => e.expenseDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        lastExpenseStr = latestDate.toIso8601String().split('T')[0];
        await prefs.setString(_lastExpenseKey, lastExpenseStr);
      }
    }

    if (lastExpenseStr == null) {
      // No expenses yet, send welcome reminder
      await _sendReminder(
        title: 'Start Tracking!',
        body: 'Add your first expense to start managing your finances.',
        type: ReminderType.welcome,
      );
      await prefs.setString(_lastReminderKey, todayStr);
      return;
    }

    final lastExpenseDate = DateTime.parse(lastExpenseStr);
    final daysSinceLastExpense = today.difference(lastExpenseDate).inDays;

    if (daysSinceLastExpense >= 7) {
      // Weekly reminder
      await _sendReminder(
        title: 'Weekly Check-in',
        body: 'It\'s been a week! Don\'t forget to log your expenses.',
        type: ReminderType.weekly,
      );
      await prefs.setString(_lastReminderKey, todayStr);
    } else if (daysSinceLastExpense >= 2) {
      // Gentle 2-day reminder
      await _sendReminder(
        title: 'Expense Reminder',
        body: 'Haven\'t added expenses in a few days. Keep tracking!',
        type: ReminderType.gentle,
      );
      await prefs.setString(_lastReminderKey, todayStr);
    }
  }

  /// Send reminder notification
  Future<void> _sendReminder({
    required String title,
    required String body,
    required ReminderType type,
  }) async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (!enabled) return;

    // Create in-app notification
    try {
      await _notificationService.createNotification(
        title: title,
        message: body,
      );
    } catch (_) {
      // Silently fail if notification table doesn't exist
    }
  }

  /// Update last expense date when a new expense is added
  Future<void> onExpenseAdded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastExpenseKey, today);
  }

  /// Get days since last expense
  Future<int> getDaysSinceLastExpense() async {
    final prefs = await SharedPreferences.getInstance();
    final lastExpenseStr = prefs.getString(_lastExpenseKey);
    
    if (lastExpenseStr == null) {
      final expenses = await _expenseService.getExpenses();
      if (expenses.isEmpty) return -1; // No expenses yet
      
      final latestDate = expenses
          .map((e) => e.expenseDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return DateTime.now().difference(latestDate).inDays;
    }

    final lastExpenseDate = DateTime.parse(lastExpenseStr);
    return DateTime.now().difference(lastExpenseDate).inDays;
  }

  /// Clear reminder preferences (for testing)
  Future<void> clearReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastReminderKey);
  }
}

enum ReminderType {
  welcome,
  gentle,
  weekly,
}
