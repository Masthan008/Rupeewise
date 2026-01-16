import 'package:flutter/material.dart';
import 'budget_service.dart';

/// Predefined budget template
class BudgetTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon; // Changed from String emoji to IconData
  final List<BudgetItem> items;

  const BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.items,
  });
}

/// Individual budget item in a template
class BudgetItem {
  final String category;
  final double suggestedAmount;
  final String? categoryIcon;

  const BudgetItem({
    required this.category,
    required this.suggestedAmount,
    this.categoryIcon,
  });
}

/// Service for managing budget templates
class BudgetTemplateService {
  final BudgetService _budgetService = BudgetService();

  /// Get all available templates
  List<BudgetTemplate> getTemplates() {
    return [
      const BudgetTemplate(
        id: 'student',
        name: 'Student Budget',
        description: 'Perfect for college students',
        icon: Icons.school,
        items: [
          BudgetItem(category: 'Food', suggestedAmount: 5000, categoryIcon: 'restaurant'),
          BudgetItem(category: 'Transport', suggestedAmount: 2000, categoryIcon: 'directions_bus'),
          BudgetItem(category: 'Entertainment', suggestedAmount: 1500, categoryIcon: 'movie'),
          BudgetItem(category: 'Books & Supplies', suggestedAmount: 1000, categoryIcon: 'book'),
          BudgetItem(category: 'Personal', suggestedAmount: 1500, categoryIcon: 'person'),
        ],
      ),
      const BudgetTemplate(
        id: 'professional',
        name: 'Young Professional',
        description: 'For working professionals',
        icon: Icons.work,
        items: [
          BudgetItem(category: 'Rent', suggestedAmount: 15000, categoryIcon: 'home'),
          BudgetItem(category: 'Food', suggestedAmount: 8000, categoryIcon: 'restaurant'),
          BudgetItem(category: 'Transport', suggestedAmount: 5000, categoryIcon: 'directions_car'),
          BudgetItem(category: 'Utilities', suggestedAmount: 3000, categoryIcon: 'bolt'),
          BudgetItem(category: 'Entertainment', suggestedAmount: 4000, categoryIcon: 'movie'),
          BudgetItem(category: 'Savings', suggestedAmount: 10000, categoryIcon: 'savings'),
        ],
      ),
      const BudgetTemplate(
        id: 'family',
        name: 'Family Budget',
        description: 'For families with kids',
        icon: Icons.family_restroom,
        items: [
          BudgetItem(category: 'Rent/EMI', suggestedAmount: 25000, categoryIcon: 'home'),
          BudgetItem(category: 'Groceries', suggestedAmount: 12000, categoryIcon: 'shopping_cart'),
          BudgetItem(category: 'Kids Education', suggestedAmount: 10000, categoryIcon: 'school'),
          BudgetItem(category: 'Utilities', suggestedAmount: 5000, categoryIcon: 'bolt'),
          BudgetItem(category: 'Healthcare', suggestedAmount: 5000, categoryIcon: 'local_hospital'),
          BudgetItem(category: 'Transport', suggestedAmount: 8000, categoryIcon: 'directions_car'),
          BudgetItem(category: 'Entertainment', suggestedAmount: 5000, categoryIcon: 'movie'),
        ],
      ),
      const BudgetTemplate(
        id: 'frugal',
        name: 'Frugal Living',
        description: 'Minimize expenses, maximize savings',
        icon: Icons.savings,
        items: [
          BudgetItem(category: 'Essentials', suggestedAmount: 10000, categoryIcon: 'shopping_bag'),
          BudgetItem(category: 'Transport', suggestedAmount: 2000, categoryIcon: 'directions_bus'),
          BudgetItem(category: 'Utilities', suggestedAmount: 2000, categoryIcon: 'bolt'),
          BudgetItem(category: 'Emergency Fund', suggestedAmount: 5000, categoryIcon: 'shield'),
        ],
      ),
      const BudgetTemplate(
        id: 'custom',
        name: '50/30/20 Rule',
        description: '50% needs, 30% wants, 20% savings',
        icon: Icons.pie_chart,
        items: [
          BudgetItem(category: 'Needs (50%)', suggestedAmount: 25000, categoryIcon: 'home'),
          BudgetItem(category: 'Wants (30%)', suggestedAmount: 15000, categoryIcon: 'shopping_cart'),
          BudgetItem(category: 'Savings (20%)', suggestedAmount: 10000, categoryIcon: 'savings'),
        ],
      ),
    ];
  }

  /// Apply a template - creates budgets for each item
  Future<void> applyTemplate(BudgetTemplate template, {double multiplier = 1.0}) async {
    for (final item in template.items) {
      await _budgetService.createBudget(
        amount: item.suggestedAmount * multiplier,
        period: BudgetPeriod.monthly,
      );
    }
  }

  /// Get template by ID
  BudgetTemplate? getTemplateById(String id) {
    try {
      return getTemplates().firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Calculate total budget for a template
  double getTemplateTotal(BudgetTemplate template) {
    double total = 0;
    for (final item in template.items) {
      total += item.suggestedAmount;
    }
    return total;
  }

  /// Scale template amounts based on income
  List<BudgetItem> scaleToIncome(BudgetTemplate template, double monthlyIncome) {
    final total = getTemplateTotal(template);
    if (total <= 0) return template.items;

    final ratio = monthlyIncome / total;
    return template.items.map((item) {
      return BudgetItem(
        category: item.category,
        suggestedAmount: (item.suggestedAmount * ratio).roundToDouble(),
        categoryIcon: item.categoryIcon,
      );
    }).toList();
  }
}
