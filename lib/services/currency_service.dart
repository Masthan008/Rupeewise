import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

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

  /// Format amount with this currency's symbol
  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '$symbol${formatter.format(amount)}';
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

  /// Format amount with currency symbol
  String formatAmount(double amount, String currencyCode) {
    final symbol = SupportedCurrencies.getSymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
