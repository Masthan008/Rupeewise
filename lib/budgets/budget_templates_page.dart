import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/budget_template_service.dart';
import '../services/currency_service.dart';
import '../core/providers/currency_provider.dart';

/// Budget templates selection page
class BudgetTemplatesPage extends ConsumerStatefulWidget {
  const BudgetTemplatesPage({super.key});

  @override
  ConsumerState<BudgetTemplatesPage> createState() => _BudgetTemplatesPageState();
}

class _BudgetTemplatesPageState extends ConsumerState<BudgetTemplatesPage> {
  final BudgetTemplateService _service = BudgetTemplateService();
  bool _isApplying = false;

  Future<void> _applyTemplate(BudgetTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply ${template.name}?'),
        content: Text(
          'This will create ${template.items.length} budget categories. '
          'You can customize amounts after applying.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isApplying = true);
      try {
        await _service.applyTemplate(template);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${template.name} applied!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final templates = _service.getTemplates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Templates'),
        centerTitle: true,
      ),
      body: _isApplying
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Applying template...'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(template, currency);
              },
            ),
    );
  }

  Widget _buildTemplateCard(BudgetTemplate template, Currency currency) {
    final total = _service.getTemplateTotal(template);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showTemplateDetails(template, currency),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      template.icon,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          template.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: template.items.take(4).map((item) {
                  return Chip(
                    label: Text(item.category, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              if (template.items.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${template.items.length - 4} more',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Total: ${currency.formatAmount(total)}/month',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDetails(BudgetTemplate template, Currency currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      template.icon,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          template.description,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: template.items.length,
                itemBuilder: (context, index) {
                  final item = template.items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(Icons.category, color: Colors.green.shade700, size: 20),
                    ),
                    title: Text(item.category),
                    trailing: Text(
                      currency.formatAmount(item.suggestedAmount),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _applyTemplate(template);
                },
                icon: const Icon(Icons.check),
                label: const Text('Apply This Template'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
