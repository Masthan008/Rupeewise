import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/budget_service.dart';
import '../core/providers/currency_provider.dart';

/// Page to add a new budget
class AddBudgetPage extends ConsumerStatefulWidget {
  const AddBudgetPage({super.key});

  @override
  ConsumerState<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends ConsumerState<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final budgetService = BudgetService();
      await budgetService.createBudget(
        amount: double.parse(_amountController.text.trim()),
        period: _selectedPeriod,
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Budget'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Budget Amount (${currency.symbol})',
                    prefixIcon: const Icon(Icons.money),
                    prefixText: '${currency.symbol} ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a budget amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Budget Period',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<BudgetPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: BudgetPeriod.weekly,
                      label: Text('Weekly'),
                      icon: Icon(Icons.calendar_view_week),
                    ),
                    ButtonSegment(
                      value: BudgetPeriod.monthly,
                      label: Text('Monthly'),
                      icon: Icon(Icons.calendar_month),
                    ),
                    ButtonSegment(
                      value: BudgetPeriod.yearly,
                      label: Text('Yearly'),
                      icon: Icon(Icons.calendar_today),
                    ),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<BudgetPeriod> newSelection) {
                    setState(() {
                      _selectedPeriod = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBudget,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Budget'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
