import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/income_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';

/// Income tracking page
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage> {
  final IncomeService _service = IncomeService();
  List<Income> _incomeList = [];
  bool _isLoading = true;
  double _monthlyTotal = 0;
  double _netBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final income = await _service.getIncome();
      final monthlyTotal = await _service.getCurrentMonthIncome();
      final netBalance = await _service.getNetBalance();

      if (mounted) {
        setState(() {
          _incomeList = income;
          _monthlyTotal = monthlyTotal;
          _netBalance = netBalance;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addIncome() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddIncomeDialog(
        currency: ref.read(currencyProvider),
      ),
    );

    if (result != null) {
      try {
        await _service.addIncome(
          amount: result['amount'],
          currency: ref.read(currencyProvider).code,
          type: result['type'],
          description: result['description'],
          incomeDate: result['date'],
          isRecurring: result['isRecurring'] ?? false,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income added!')),
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

  Future<void> _deleteIncome(Income income) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: Text('Delete "${income.description ?? income.typeDisplayName}"?'),
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
        await _service.deleteIncome(income.id);
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

  IconData _getTypeIcon(IncomeType type) {
    switch (type) {
      case IncomeType.salary:
        return Icons.work;
      case IncomeType.freelance:
        return Icons.laptop;
      case IncomeType.investment:
        return Icons.trending_up;
      case IncomeType.business:
        return Icons.business;
      case IncomeType.rental:
        return Icons.home;
      case IncomeType.gift:
        return Icons.card_giftcard;
      case IncomeType.refund:
        return Icons.replay;
      case IncomeType.other:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Summary cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Monthly Income',
                            currency.formatAmount(_monthlyTotal),
                            Colors.green,
                            Icons.arrow_upward,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Net Balance',
                            currency.formatAmount(_netBalance),
                            _netBalance >= 0 ? Colors.blue : Colors.red,
                            _netBalance >= 0 ? Icons.account_balance : Icons.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Income list
                  Expanded(
                    child: _incomeList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No income recorded',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your income sources',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _incomeList.length,
                            itemBuilder: (context, index) {
                              final income = _incomeList[index];
                              return _buildIncomeCard(income, currency);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIncome,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(Income income, Currency currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getTypeIcon(income.type), color: Colors.green),
        ),
        title: Text(income.description ?? income.typeDisplayName),
        subtitle: Text(
          '${income.typeDisplayName} • ${DateFormat('MMM d, yyyy').format(income.incomeDate)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${currency.formatAmount(income.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteIncome(income),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to add new income
class _AddIncomeDialog extends StatefulWidget {
  final Currency currency;

  const _AddIncomeDialog({required this.currency});

  @override
  State<_AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<_AddIncomeDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  IncomeType _type = IncomeType.salary;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
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
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
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
        'type': _type,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'date': _date,
        'isRecurring': _isRecurring,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income'),
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
            DropdownButtonFormField<IncomeType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: IncomeType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('MMMM d, yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring income'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value ?? false),
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
