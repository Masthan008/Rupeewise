import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/spending_limit_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';

/// Spending limits settings page
class SpendingLimitsPage extends ConsumerStatefulWidget {
  const SpendingLimitsPage({super.key});

  @override
  ConsumerState<SpendingLimitsPage> createState() => _SpendingLimitsPageState();
}

class _SpendingLimitsPageState extends ConsumerState<SpendingLimitsPage> {
  final SpendingLimitService _service = SpendingLimitService();
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _alertsEnabled = true;
  int _alertThreshold = 80;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    setState(() => _isLoading = true);
    try {
      final limits = await _service.getSpendingLimits();
      if (limits != null && mounted) {
        setState(() {
          _dailyController.text = limits.dailyLimit > 0 ? limits.dailyLimit.toStringAsFixed(0) : '';
          _weeklyController.text = limits.weeklyLimit > 0 ? limits.weeklyLimit.toStringAsFixed(0) : '';
          _monthlyController.text = limits.monthlyLimit > 0 ? limits.monthlyLimit.toStringAsFixed(0) : '';
          _alertsEnabled = limits.alertsEnabled;
          _alertThreshold = limits.alertThreshold;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveLimits() async {
    setState(() => _isSaving = true);
    try {
      await _service.saveSpendingLimits(
        dailyLimit: double.tryParse(_dailyController.text) ?? 0,
        weeklyLimit: double.tryParse(_weeklyController.text) ?? 0,
        monthlyLimit: double.tryParse(_monthlyController.text) ?? 0,
        alertThreshold: _alertThreshold,
        alertsEnabled: _alertsEnabled,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending limits saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Limits'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveLimits,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Set spending limits to get alerts when you\'re close to or exceed your budget.',
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Limits section
                  const Text(
                    'Set Your Limits',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildLimitField(
                    label: 'Daily Limit',
                    icon: Icons.today,
                    controller: _dailyController,
                    currency: currency,
                    hint: 'e.g., 500',
                  ),
                  const SizedBox(height: 16),
                  _buildLimitField(
                    label: 'Weekly Limit',
                    icon: Icons.date_range,
                    controller: _weeklyController,
                    currency: currency,
                    hint: 'e.g., 3000',
                  ),
                  const SizedBox(height: 16),
                  _buildLimitField(
                    label: 'Monthly Limit',
                    icon: Icons.calendar_month,
                    controller: _monthlyController,
                    currency: currency,
                    hint: 'e.g., 15000',
                  ),
                  const SizedBox(height: 32),

                  // Alert settings
                  const Text(
                    'Alert Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Alerts'),
                          subtitle: const Text('Get notified when approaching limits'),
                          value: _alertsEnabled,
                          onChanged: (value) => setState(() => _alertsEnabled = value),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Alert Threshold'),
                          subtitle: Text('Notify at $_alertThreshold% of limit'),
                          trailing: SizedBox(
                            width: 150,
                            child: Slider(
                              value: _alertThreshold.toDouble(),
                              min: 50,
                              max: 95,
                              divisions: 9,
                              label: '$_alertThreshold%',
                              onChanged: (value) => setState(() => _alertThreshold = value.round()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLimitField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Currency currency,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: '${currency.symbol} ',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
