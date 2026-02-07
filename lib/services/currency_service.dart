import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'exchange_rate_service.dart';

/// Supported currencies with their symbols
class Currency {
  final String code;
  final String name;
  final String symbol;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  /// Format amount with this currency's symbol (converts from USD base)
  String formatAmount(double amountInUsd) {
    final exchangeService = ExchangeRateService();
    final convertedAmount = exchangeService.convertFromBase(amountInUsd, code);
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '$symbol${formatter.format(convertedAmount)}';
  }
  
  /// Format amount without conversion (for display currency amounts)
  String formatRaw(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '$symbol${formatter.format(amount)}';
  }
  
  /// Convert user input to USD for storage
  double toUsd(double amountInLocalCurrency) {
    final exchangeService = ExchangeRateService();
    return exchangeService.convertToBase(amountInLocalCurrency, code);
  }
  
  /// Convert from USD to this currency for display
  double fromUsd(double amountInUsd) {
    final exchangeService = ExchangeRateService();
    return exchangeService.convertFromBase(amountInUsd, code);
  }
  
  /// Get rate change percentage for this currency
  double? getRateChange() {
    final exchangeService = ExchangeRateService();
    return exchangeService.getRateChange(code);
  }
  
  /// Get current exchange rate (1 USD = X this currency)
  double getRate() {
    final exchangeService = ExchangeRateService();
    return exchangeService.getRate(code);
  }
}

/// List of supported currencies
class SupportedCurrencies {
  static const List<Currency> currencies = [
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
  ];

  static Currency get defaultCurrency => currencies.first; // INR
  
  /// Base currency for storage (all amounts stored in USD)
  static Currency get baseCurrency => currencies[1]; // USD

  static Currency? getByCode(String code) {
    try {
      return currencies.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  static String getSymbol(String code) {
    return getByCode(code)?.symbol ?? code;
  }
}

/// Service for managing user's preferred currency
class CurrencyService {
  final _client = SupabaseService.instance.client;

  /// Get current user's preferred currency
  Future<String> getPreferredCurrency() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return 'INR';

    try {
      final response = await _client
          .from('users_profile')
          .select('preferred_currency')
          .eq('id', userId)
          .single();

      return response['preferred_currency'] as String? ?? 'INR';
    } catch (_) {
      return 'INR';
    }
  }

  /// Update user's preferred currency
  Future<void> setPreferredCurrency(String currencyCode) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('users_profile')
        .update({'preferred_currency': currencyCode})
        .eq('id', userId);
  }

  /// Format amount with currency symbol (converts from USD)
  String formatAmount(double amountInUsd, String currencyCode) {
    final currency = SupportedCurrencies.getByCode(currencyCode);
    if (currency == null) {
      return '\$${amountInUsd.toStringAsFixed(2)}';
    }
    return currency.formatAmount(amountInUsd);
  }
  
  /// Convert local currency amount to USD for storage
  double convertToUsd(double amount, String fromCurrency) {
    final currency = SupportedCurrencies.getByCode(fromCurrency);
    if (currency == null || fromCurrency == 'USD') return amount;
    return currency.toUsd(amount);
  }
  
  /// Convert USD to local currency for display
  double convertFromUsd(double amountInUsd, String toCurrency) {
    final currency = SupportedCurrencies.getByCode(toCurrency);
    if (currency == null || toCurrency == 'USD') return amountInUsd;
    return currency.fromUsd(amountInUsd);
  }
}
