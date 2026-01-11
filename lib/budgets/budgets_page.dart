import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../core/providers/currency_provider.dart';

/// Budgets page showing budget list and creation
class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  final BudgetService _budgetService = BudgetService();
  final ExpenseService _expenseService = ExpenseService();
  List<Budget> _budgets = [];
  Map<String, double> _budgetSpending = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _budgetService.getActiveBudgets();
      final spending = <String, double>{};

      for (final budget in budgets) {
        final expenses = await _expenseService.getExpensesByDateRange(
          budget.startDate,
          budget.endDate,
        );
        double total = 0;
        for (final expense in expenses) {
          if (budget.categoryId == null ||
              expense.categoryId == budget.categoryId) {
            total += expense.amount;
          }
        }
        spending[budget.id] = total;
      }

      if (mounted) {
        setState(() {
          _budgets = budgets;
          _budgetSpending = spending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
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
        await _budgetService.deleteBudget(budget.id);
        await _loadBudgets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted')),
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
        title: const Text('Budgets'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgets,
              child: _budgets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No budgets yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a budget to track your spending',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _budgets.length,
                      itemBuilder: (context, index) {
                        final budget = _budgets[index];
                        final spent = _budgetSpending[budget.id] ?? 0;
                        final progress = budget.amount > 0
                            ? (spent / budget.amount).clamp(0.0, 1.0)
                            : 0.0;
                        final isOverBudget = spent > budget.amount;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Budget status icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isOverBudget
                                            ? Colors.red.shade100
                                            : progress > 0.8
                                                ? Colors.orange.shade100
                                                : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isOverBudget
                                            ? Icons.warning
                                            : progress > 0.8
                                                ? Icons.trending_up
                                                : Icons.check_circle,
                                        color: isOverBudget
                                            ? Colors.red
                                            : progress > 0.8
                                                ? Colors.orange
                                                : Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${budget.period.name.substring(0, 1).toUpperCase()}${budget.period.name.substring(1)} Budget',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${DateFormat('MMM d').format(budget.startDate)} - ${DateFormat('MMM d').format(budget.endDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () => _deleteBudget(budget),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currency.formatAmount(spent),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isOverBudget
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'of ${currency.formatAmount(budget.amount)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                    isOverBudget
                                        ? Colors.red
                                        : progress > 0.8
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isOverBudget
                                          ? 'Over budget by ${currency.formatAmount(spent - budget.amount)}'
                                          : '${currency.formatAmount(budget.amount - spent)} remaining',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOverBudget
                                            ? Colors.red
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (isOverBudget)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'EXCEEDED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-budget');
          if (result == true) {
            _loadBudgets();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
