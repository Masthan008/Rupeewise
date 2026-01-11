import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/currency_service.dart';

/// Provider for the user's preferred currency
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

/// Notifier to manage currency state
class CurrencyNotifier extends StateNotifier<Currency> {
  final CurrencyService _currencyService = CurrencyService();

  CurrencyNotifier() : super(SupportedCurrencies.currencies.first) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final code = await _currencyService.getPreferredCurrency();
      final currency = SupportedCurrencies.getByCode(code);
      if (currency != null) {
        state = currency;
      }
    } catch (_) {
      // Default to INR
    }
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      await _currencyService.setPreferredCurrency(currency.code);
      state = currency;
    } catch (_) {
      // Handle error
    }
  }

  /// Format amount with currency symbol
  String formatAmount(double amount) {
    return state.formatAmount(amount);
  }

  /// Get currency symbol
  String get symbol => state.symbol;

  /// Get currency code
  String get code => state.code;

  /// Refresh currency from database
  Future<void> refresh() async {
    await _loadCurrency();
  }
}

/// Provider for currency service
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});
