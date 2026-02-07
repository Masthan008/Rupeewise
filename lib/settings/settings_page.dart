import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../core/providers/currency_provider.dart';
import '../core/providers/theme_provider.dart';

/// Settings page with user preferences
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = true;
  bool _rateAlertsEnabled = false;
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final notifEnabled = await _notificationService.areNotificationsEnabled();
      final user = SupabaseService.instance.currentUser;

      if (user != null) {
        try {
          final profile = await SupabaseService.instance.client
              .from('users_profile')
              .select('full_name, email')
              .eq('id', user.id)
              .single();

          if (mounted) {
            setState(() {
              _userName = profile['full_name'] ?? 'User';
              _userEmail = profile['email'] ?? user.email ?? '';
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _userName = 'User';
              _userEmail = user.email ?? '';
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _notificationsEnabled = notifEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateCurrency(Currency currency) async {
    try {
      await ref.read(currencyProvider.notifier).setCurrency(currency);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Currency changed to ${currency.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateNotifications(bool enabled) async {
    try {
      await _notificationService.setNotificationsEnabled(enabled);
      setState(() {
        _notificationsEnabled = enabled;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService().logout();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              children: [
                // User profile card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Currency setting
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.currency_exchange),
                        title: const Text('Currency'),
                        subtitle: Text('${currency.symbol} ${currency.name}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCurrencyPicker(),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: const Text('Notifications'),
                        subtitle: const Text('Budget alerts and summaries'),
                        value: _notificationsEnabled,
                        onChanged: _updateNotifications,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          ref.watch(themeModeProvider) == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        title: const Text('Dark Mode'),
                        subtitle: Text(
                          ref.watch(themeModeProvider) == ThemeMode.dark
                              ? 'Dark theme enabled'
                              : 'Light theme enabled',
                        ),
                        value: ref.watch(themeModeProvider) == ThemeMode.dark,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.currency_exchange),
                        title: const Text('Rate Alerts'),
                        subtitle: const Text('Daily exchange rate updates'),
                        value: _rateAlertsEnabled,
                        onChanged: (value) {
                          setState(() => _rateAlertsEnabled = value);
                          // TODO: Implement notification scheduling
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout button
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red.shade400),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                    onTap: _logout,
                  ),
                ),
                const SizedBox(height: 24),

                // App info
                Center(
                  child: Text(
                    'RupeeWise v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCurrencyPicker() {
    final currentCurrency = ref.read(currencyProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: SupportedCurrencies.currencies.length,
                itemBuilder: (context, index) {
                  final currency = SupportedCurrencies.currencies[index];
                  final isSelected = currency.code == currentCurrency.code;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade100,
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    trailing: isSelected
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _updateCurrency(currency);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
