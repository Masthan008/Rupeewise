import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/expense_shortcut_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';

/// Quick expense shortcuts widget for dashboard
class QuickShortcutsWidget extends ConsumerStatefulWidget {
  const QuickShortcutsWidget({super.key});

  @override
  ConsumerState<QuickShortcutsWidget> createState() => _QuickShortcutsWidgetState();
}

class _QuickShortcutsWidgetState extends ConsumerState<QuickShortcutsWidget> {
  final ExpenseShortcutService _service = ExpenseShortcutService();
  List<ExpenseShortcut> _shortcuts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final shortcuts = await _service.getShortcuts();
    if (mounted) {
      setState(() {
        _shortcuts = shortcuts.take(4).toList(); // Show top 4
        _isLoading = false;
      });
    }
  }

  Future<void> _useShortcut(ExpenseShortcut shortcut) async {
    final currency = ref.read(currencyProvider);
    
    try {
      await _service.useShortcut(shortcut, currency.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${shortcut.name} - ${currency.formatAmount(shortcut.amount)}'),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadShortcuts(); // Refresh to update usage count
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'coffee':
        return Icons.coffee;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'fastfood':
        return Icons.fastfood;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'local_gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    if (_isLoading) {
      return const SizedBox(height: 80);
    }

    if (_shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showManageDialog(),
                child: const Text('Manage'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _shortcuts.length,
            itemBuilder: (context, index) {
              final shortcut = _shortcuts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildShortcutCard(shortcut, currency),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard(ExpenseShortcut shortcut, Currency currency) {
    return Card(
      child: InkWell(
        onTap: () => _useShortcut(shortcut),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(shortcut.icon),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                shortcut.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                currency.formatAmount(shortcut.amount),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ManageShortcutsSheet(
        service: _service,
        onUpdate: _loadShortcuts,
      ),
    );
  }
}

/// Bottom sheet for managing shortcuts
class _ManageShortcutsSheet extends StatefulWidget {
  final ExpenseShortcutService service;
  final VoidCallback onUpdate;

  const _ManageShortcutsSheet({
    required this.service,
    required this.onUpdate,
  });

  @override
  State<_ManageShortcutsSheet> createState() => _ManageShortcutsSheetState();
}

class _ManageShortcutsSheetState extends State<_ManageShortcutsSheet> {
  List<ExpenseShortcut> _shortcuts = [];

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final shortcuts = await widget.service.getShortcuts();
    if (mounted) {
      setState(() => _shortcuts = shortcuts);
    }
  }

  Future<void> _deleteShortcut(ExpenseShortcut shortcut) async {
    await widget.service.deleteShortcut(shortcut.id);
    await _loadShortcuts();
    widget.onUpdate();
  }

  Future<void> _addShortcut() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddShortcutDialog(),
    );

    if (result != null) {
      final shortcut = widget.service.createShortcut(
        name: result['name'],
        amount: result['amount'],
        icon: result['icon'],
      );
      await widget.service.addShortcut(shortcut);
      await _loadShortcuts();
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Shortcuts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addShortcut,
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _shortcuts.length,
              itemBuilder: (context, index) {
                final shortcut = _shortcuts[index];
                return ListTile(
                  leading: Icon(Icons.payments),
                  title: Text(shortcut.name),
                  subtitle: Text('₹${shortcut.amount.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteShortcut(shortcut),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to add a new shortcut
class _AddShortcutDialog extends StatefulWidget {
  const _AddShortcutDialog();

  @override
  State<_AddShortcutDialog> createState() => _AddShortcutDialogState();
}

class _AddShortcutDialogState extends State<_AddShortcutDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid name and amount')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'amount': amount,
      'icon': 'payments',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Shortcut'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Coffee, Lunch',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              hintText: 'e.g., 50',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
