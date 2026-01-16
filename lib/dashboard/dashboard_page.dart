import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import '../services/supabase_service.dart';
import '../core/utils/category_icons.dart';
import '../core/providers/currency_provider.dart';

/// Dashboard page showing expense summary
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _userName = '';
  List<Expense> _expenses = [];
  Map<String, Category> _categoryMap = {};
  double _monthTotal = 0;
  bool _isLoading = true;
  final _expenseService = ExpenseService();
  final _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Refresh currency from database
      ref.read(currencyProvider.notifier).refresh();
      
      await Future.wait([
        _loadUserData(),
        _loadExpenses(),
        _loadCategories(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final profile = await SupabaseService.instance.client
            .from('users_profile')
            .select('full_name')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _userName = profile['full_name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User';
        });
      }
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await _expenseService.getExpenses();
      final monthTotal = await _expenseService.getCurrentMonthTotal();
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _monthTotal = monthTotal;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadCategories() async {
    try {
      await _categoryService.seedDefaultCategories();
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categoryMap = {for (var c in categories) c.id: c};
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
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
        await _expenseService.deleteExpense(expense.id);
        await _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted')),
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
        title: const Text('RupeeWise'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    // Monthly summary card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $_userName!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This Month',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withAlpha(179),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.formatAmount(_monthTotal),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Recent expenses header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_expenses.isNotEmpty)
                            TextButton(
                              onPressed: () => context.push('/analytics'),
                              child: const Text('View All'),
                            ),
                        ],
                      ),
                    ),
                    // Expenses list
                    Expanded(
                      child: _expenses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No expenses yet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first expense to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _expenses.length > 10
                                  ? 10
                                  : _expenses.length,
                              itemBuilder: (context, index) {
                                final expense = _expenses[index];
                                final category = expense.categoryId != null
                                    ? _categoryMap[expense.categoryId]
                                    : null;

                                IconData icon = Icons.receipt;
                                Color iconColor =
                                    Theme.of(context).colorScheme.primary;

                                if (category != null) {
                                  icon = CategoryIcons.getIcon(category.icon);
                                  iconColor = _parseColor(category.color);
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: iconColor.withAlpha(51),
                                      child: Icon(icon, color: iconColor),
                                    ),
                                    title: Text(
                                      expense.description ??
                                          category?.name ??
                                          'Expense',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      DateFormat('MMM d, yyyy')
                                          .format(expense.expenseDate),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currency.formatAmount(expense.amount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          onPressed: () =>
                                              _deleteExpense(expense),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Bottom padding for glass navigation bar
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.push('/add-expense');
            if (result == true) {
              _loadExpenses();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }
}
