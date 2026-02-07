import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/exchange_rate_service.dart';
import '../core/providers/currency_provider.dart';

/// Widget showing exchange rate insights with change indicators
class ExchangeRateCard extends ConsumerWidget {
  const ExchangeRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCurrency = ref.watch(currencyProvider);
    final exchangeService = ExchangeRateService();
    
    // Skip if user currency is USD (base currency)
    if (userCurrency.code == 'USD') {
      return const SizedBox.shrink();
    }
    
    final rate = exchangeService.getRate(userCurrency.code);
    final rateChange = exchangeService.getRateChange(userCurrency.code);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Exchange Rate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                if (rateChange != null) _buildChangeChip(rateChange, context),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '1 USD = ',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${userCurrency.symbol}${rate.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  userCurrency.code,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getInsightText(rateChange, userCurrency.code),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChangeChip(double change, BuildContext context) {
    final isPositive = change > 0;
    final isNeutral = change.abs() < 0.01;
    
    Color chipColor;
    IconData icon;
    
    if (isNeutral) {
      chipColor = Colors.grey;
      icon = Icons.remove;
    } else if (isPositive) {
      // Rate increased = local currency weakened
      chipColor = Colors.red;
      icon = Icons.trending_up;
    } else {
      // Rate decreased = local currency strengthened
      chipColor = Colors.green;
      icon = Icons.trending_down;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getInsightText(double? change, String currencyCode) {
    if (change == null) {
      return 'Rates updated daily';
    }
    
    final absChange = change.abs();
    if (absChange < 0.01) {
      return 'Rate unchanged from yesterday';
    } else if (change > 0) {
      return '$currencyCode weakened ${absChange.toStringAsFixed(2)}% vs USD';
    } else {
      return '$currencyCode strengthened ${absChange.toStringAsFixed(2)}% vs USD';
    }
  }
}

/// Compact version for smaller spaces
class ExchangeRateBadge extends ConsumerWidget {
  const ExchangeRateBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCurrency = ref.watch(currencyProvider);
    final exchangeService = ExchangeRateService();
    
    if (userCurrency.code == 'USD') {
      return const SizedBox.shrink();
    }
    
    final rate = exchangeService.getRate(userCurrency.code);
    final rateChange = exchangeService.getRateChange(userCurrency.code);
    
    final changeColor = rateChange == null || rateChange.abs() < 0.01
        ? Colors.grey
        : (rateChange > 0 ? Colors.red : Colors.green);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.currency_exchange,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${userCurrency.symbol}${rate.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (rateChange != null && rateChange.abs() >= 0.01) ...[
            const SizedBox(width: 4),
            Icon(
              rateChange > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: changeColor,
            ),
          ],
        ],
      ),
    );
  }
}
