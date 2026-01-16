import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/recurring_expense_service.dart';
import '../services/category_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';
import '../core/utils/category_icons.dart';

/// Recurring expenses page
class RecurringExpensesPage extends ConsumerStatefulWidget {
  const RecurringExpensesPage({super.key});

  @override
  ConsumerState<RecurringExpensesPage> createState() => _RecurringExpensesPageState();
}

class _RecurringExpensesPageState extends ConsumerState<RecurringExpensesPage> {
  final RecurringExpenseService _service = RecurringExpenseService();
  final CategoryService _categoryService = CategoryService();
  List<RecurringExpense> _expenses = [];
  Map<String, Category> _categoryMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _service.getRecurringExpenses();
      final categories = await _categoryService.getCategories();
      
      // Process due expenses on load
      await _service.processDueExpenses();
      
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _categoryMap = {for (var c in categories) c.id: c};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addRecurring() async {
    final categories = await _categoryService.getCategories();
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddRecurringDialog(
        currency: ref.read(currencyProvider),
        categories: categories,
      ),
    );

    if (result != null) {
      try {
        await _service.createRecurringExpense(
          amount: result['amount'],
          currency: ref.read(currencyProvider).code,
          categoryId: result['categoryId'],
          description: result['description'],
          frequency: result['frequency'],
          startDate: result['startDate'],
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring expense created!')),
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

  Future<void> _toggleActive(RecurringExpense expense) async {
    try {
      await _service.toggleActive(expense.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(expense.isActive ? 'Paused' : 'Resumed')),
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

  Future<void> _delete(RecurringExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Expense'),
        content: Text('Delete "${expense.description ?? 'this recurring expense'}"?'),
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
        await _service.deleteRecurringExpense(expense.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted')),
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

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No recurring expenses',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add expenses that repeat automatically',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return _buildExpenseCard(expense, currency);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecurring,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseCard(RecurringExpense expense, Currency currency) {
    final category = expense.categoryId != null ? _categoryMap[expense.categoryId] : null;
    IconData icon = Icons.repeat;
    Color iconColor = Theme.of(context).colorScheme.primary;

    if (category != null) {
      icon = CategoryIcons.getIcon(category.icon);
      iconColor = _parseColor(category.color);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: expense.isActive ? iconColor.withAlpha(26) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: expense.isActive ? iconColor : Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description ?? category?.name ?? 'Recurring Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: expense.isActive ? null : Colors.grey,
                        ),
                      ),
                      Text(
                        expense.frequencyDisplayName,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.formatAmount(expense.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: expense.isActive ? null : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (expense.nextExecutionDate != null)
                  Expanded(
                    child: Text(
                      'Next: ${DateFormat('MMM d, yyyy').format(expense.nextExecutionDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: expense.isActive ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expense.isActive ? 'Active' : 'Paused',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: expense.isActive ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleActive(expense),
                  icon: Icon(expense.isActive ? Icons.pause : Icons.play_arrow, size: 18),
                  label: Text(expense.isActive ? 'Pause' : 'Resume'),
                ),
                TextButton.icon(
                  onPressed: () => _delete(expense),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to add a new recurring expense
class _AddRecurringDialog extends StatefulWidget {
  final Currency currency;
  final List<Category> categories;

  const _AddRecurringDialog({required this.currency, required this.categories});

  @override
  State<_AddRecurringDialog> createState() => _AddRecurringDialogState();
}

class _AddRecurringDialogState extends State<_AddRecurringDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    setState(() {
      _amountError = (amount == null || amount <= 0) ? 'Enter valid amount' : null;
    });

    if (_amountError == null) {
      Navigator.pop(context, {
        'amount': amount,
        'categoryId': _selectedCategoryId,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'frequency': _frequency,
        'startDate': _startDate,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Recurring Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (${widget.currency.symbol})',
                border: const OutlineInputBorder(),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Netflix, Rent, Gym',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No category')),
                ...widget.categories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceFrequency.values.map((f) {
                String label;
                switch (f) {
                  case RecurrenceFrequency.daily:
                    label = 'Daily';
                    break;
                  case RecurrenceFrequency.weekly:
                    label = 'Weekly';
                    break;
                  case RecurrenceFrequency.biweekly:
                    label = 'Bi-weekly';
                    break;
                  case RecurrenceFrequency.monthly:
                    label = 'Monthly';
                    break;
                  case RecurrenceFrequency.quarterly:
                    label = 'Quarterly';
                    break;
                  case RecurrenceFrequency.yearly:
                    label = 'Yearly';
                    break;
                }
                return DropdownMenuItem(value: f, child: Text(label));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('MMMM d, yyyy').format(_startDate)),
              ),
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
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
