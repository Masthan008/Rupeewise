import '../services/supabase_service.dart';

/// Notification types
enum NotificationType { info, warning, success, alert }

/// Model class for notification data
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: _parseNotificationType(json['type'] as String?),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'warning':
        return NotificationType.warning;
      case 'success':
        return NotificationType.success;
      case 'alert':
        return NotificationType.alert;
      default:
        return NotificationType.info;
    }
  }
}

/// User notification preferences
class NotificationPreferences {
  final bool budgetWarnings;
  final bool weeklySummary;
  final bool monthlySummary;

  const NotificationPreferences({
    this.budgetWarnings = true,
    this.weeklySummary = true,
    this.monthlySummary = true,
  });
}

/// Service for managing notifications in Supabase
class NotificationService {
  final _client = SupabaseService.instance.client;

  /// Get all notifications for current user
  Future<List<AppNotification>> getNotifications() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Create a notification
  Future<AppNotification> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'is_read': false,
    }).select().single();

    return AppNotification.fromJson(response);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  /// Create budget warning notification
  Future<void> sendBudgetWarning({
    required String budgetName,
    required double percentUsed,
  }) async {
    await createNotification(
      title: 'Budget Warning',
      message: 'You have used ${percentUsed.toStringAsFixed(0)}% of your $budgetName budget.',
      type: NotificationType.warning,
    );
  }

  /// Create weekly summary notification
  Future<void> sendWeeklySummary({
    required double totalSpent,
    required int transactionCount,
  }) async {
    await createNotification(
      title: 'Weekly Summary',
      message: 'This week you spent ₹${totalSpent.toStringAsFixed(2)} across $transactionCount transactions.',
      type: NotificationType.info,
    );
  }

  /// Create monthly summary notification
  Future<void> sendMonthlySummary({
    required double totalSpent,
    required int transactionCount,
    required double changeFromLastMonth,
  }) async {
    final changeText = changeFromLastMonth >= 0
        ? '${changeFromLastMonth.toStringAsFixed(0)}% more than last month'
        : '${changeFromLastMonth.abs().toStringAsFixed(0)}% less than last month';

    await createNotification(
      title: 'Monthly Summary',
      message: 'This month you spent ₹${totalSpent.toStringAsFixed(2)} ($changeText).',
      type: NotificationType.info,
    );
  }

  /// Check if notifications are enabled for user
  Future<bool> areNotificationsEnabled() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('users_profile')
          .select('notifications_enabled')
          .eq('id', userId)
          .single();

      return response['notifications_enabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('users_profile')
        .update({'notifications_enabled': enabled})
        .eq('id', userId);
  }
}
