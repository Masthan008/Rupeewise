import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/savings_goal_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';

/// Savings goals page
class SavingsGoalsPage extends ConsumerStatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  ConsumerState<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends ConsumerState<SavingsGoalsPage> {
  final SavingsGoalService _goalService = SavingsGoalService();
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalService.getGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addGoal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddGoalDialog(
        currency: ref.read(currencyProvider),
      ),
    );

    if (result != null) {
      try {
        await _goalService.createGoal(
          name: result['name'],
          targetAmount: result['targetAmount'],
          targetDate: result['targetDate'],
          description: result['description'],
        );
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal created!')),
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
  }

  Future<void> _addToGoal(SavingsGoal goal) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _AddAmountDialog(
        currency: ref.read(currencyProvider),
        goalName: goal.name,
      ),
    );

    if (result != null && result > 0) {
      try {
        await _goalService.addToGoal(goalId: goal.id, amount: result);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${ref.read(currencyProvider).formatAmount(result)} to ${goal.name}')),
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
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _goalService.deleteGoal(goal.id);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted')),
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
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: _goals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No savings goals yet',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a goal to start saving',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return _buildGoalCard(goal, currency);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal, Currency currency) {
    final progress = goal.progressPercentage / 100;
    final isCompleted = goal.isCompleted;
    final isOverdue = goal.isOverdue;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed!';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Overdue';
    } else if (goal.daysRemaining <= 7) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = '${goal.daysRemaining} days left';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.flag;
      statusText = '${goal.daysRemaining} days left';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isCompleted ? null : () => _addToGoal(goal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (goal.description != null && goal.description!.isNotEmpty)
                          Text(
                            goal.description!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteGoal(goal),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currency.formatAmount(goal.currentAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : null,
                    ),
                  ),
                  Text(
                    'of ${currency.formatAmount(goal.targetAmount)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                    ),
                  ),
                ],
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  'Target: ${DateFormat('MMM d, yyyy').format(goal.targetDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog to add a new savings goal
class _AddGoalDialog extends StatefulWidget {
  final Currency currency;

  const _AddGoalDialog({required this.currency});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  String? _nameError;
  String? _amountError;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _validateAndSubmit() {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    setState(() {
      _nameError = name.isEmpty ? 'Please enter a goal name' : null;
      _amountError = amountText.isEmpty
          ? 'Please enter an amount'
          : (amount == null || amount <= 0)
              ? 'Please enter a valid amount'
              : null;
    });

    if (_nameError == null && _amountError == null) {
      Navigator.pop(context, {
        'name': name,
        'targetAmount': amount,
        'targetDate': _targetDate,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Savings Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Emergency Fund, Vacation',
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Amount (${widget.currency.symbol})',
                border: const OutlineInputBorder(),
                errorText: _amountError,
              ),
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Target Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('MMMM d, yyyy').format(_targetDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _validateAndSubmit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog to add amount to a goal
class _AddAmountDialog extends StatefulWidget {
  final Currency currency;
  final String goalName;

  const _AddAmountDialog({required this.currency, required this.goalName});

  @override
  State<_AddAmountDialog> createState() => _AddAmountDialogState();
}

class _AddAmountDialogState extends State<_AddAmountDialog> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to "${widget.goalName}"'),
      content: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Amount (${widget.currency.symbol})',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text.trim());
            if (amount != null && amount > 0) {
              Navigator.pop(context, amount);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
