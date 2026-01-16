import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Currency exchange rate model
class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;

  ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      fromCurrency: json['from'] as String,
      toCurrency: json['to'] as String,
      rate: (json['rate'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'from': fromCurrency,
    'to': toCurrency,
    'rate': rate,
    'updated': lastUpdated.toIso8601String(),
  };
}

/// Service for multi-currency conversion
class CurrencyConversionService {
  static const String _cacheKey = 'exchange_rates_cache';
  
  // Hardcoded rates (INR base) - in production, fetch from API
  static final Map<String, double> _defaultRates = {
    'INR': 1.0,
    'USD': 0.012,    // 1 INR = 0.012 USD
    'EUR': 0.011,    // 1 INR = 0.011 EUR
    'GBP': 0.0095,   // 1 INR = 0.0095 GBP
    'AED': 0.044,    // 1 INR = 0.044 AED
    'SGD': 0.016,    // 1 INR = 0.016 SGD
    'AUD': 0.018,    // 1 INR = 0.018 AUD
    'CAD': 0.016,    // 1 INR = 0.016 CAD
    'JPY': 1.8,      // 1 INR = 1.8 JPY
    'CNY': 0.086,    // 1 INR = 0.086 CNY
  };

  /// Convert amount from one currency to another
  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    // Convert to INR first, then to target currency
    final toInr = amount / (_defaultRates[fromCurrency] ?? 1.0);
    final toTarget = toInr * (_defaultRates[toCurrency] ?? 1.0);
    
    return toTarget;
  }

  /// Get exchange rate between two currencies
  double getRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;
    
    final fromRate = _defaultRates[fromCurrency] ?? 1.0;
    final toRate = _defaultRates[toCurrency] ?? 1.0;
    
    return toRate / fromRate;
  }

  /// Get all supported currencies
  List<String> getSupportedCurrencies() {
    return _defaultRates.keys.toList();
  }

  /// Format amount in target currency
  String formatConverted(double amount, String fromCurrency, String toCurrency) {
    final converted = convert(amount, fromCurrency, toCurrency);
    return '${_getSymbol(toCurrency)}${converted.toStringAsFixed(2)}';
  }

  String _getSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AED': return 'د.إ';
      case 'SGD': return 'S\$';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'JPY': return '¥';
      case 'CNY': return '¥';
      default: return currencyCode;
    }
  }

  /// Cache exchange rates
  Future<void> cacheRates(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'rates': rates,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_cacheKey, json.encode(cacheData));
  }

  /// Get cached rates
  Future<Map<String, double>?> getCachedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheStr = prefs.getString(_cacheKey);
    if (cacheStr == null) return null;

    try {
      final cacheData = json.decode(cacheStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Cache valid for 24 hours
      if (DateTime.now().difference(timestamp).inHours > 24) {
        return null;
      }

      final rates = (cacheData['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      return rates;
    } catch (_) {
      return null;
    }
  }

  /// Get rate display string
  String getRateDisplay(String fromCurrency, String toCurrency) {
    final rate = getRate(fromCurrency, toCurrency);
    return '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency';
  }

  /// Convert expense list to target currency
  List<Map<String, dynamic>> convertExpenses(
    List<Map<String, dynamic>> expenses,
    String targetCurrency,
  ) {
    return expenses.map((expense) {
      final amount = (expense['amount'] as num).toDouble();
      final currency = expense['currency'] as String? ?? 'INR';
      
      return {
        ...expense,
        'original_amount': amount,
        'original_currency': currency,
        'converted_amount': convert(amount, currency, targetCurrency),
        'display_currency': targetCurrency,
      };
    }).toList();
  }
}
