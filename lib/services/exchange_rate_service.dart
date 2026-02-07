import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for fetching and caching exchange rates from free API
class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate.host/latest';
  static const String _baseCurrency = 'USD'; // All amounts stored in USD
  static const String _ratesKey = 'exchange_rates';
  static const String _rateDateKey = 'exchange_rate_date';
  static const String _previousRatesKey = 'previous_exchange_rates';
  
  static ExchangeRateService? _instance;
  Map<String, double> _rates = {};
  Map<String, double> _previousRates = {};
  DateTime? _lastFetchDate;
  
  ExchangeRateService._();
  
  factory ExchangeRateService() {
    _instance ??= ExchangeRateService._();
    return _instance!;
  }
  
  /// Base currency used for storage
  String get baseCurrency => _baseCurrency;
  
  /// Get cached rates
  Map<String, double> get rates => Map.unmodifiable(_rates);
  
  /// Get previous day rates for comparison
  Map<String, double> get previousRates => Map.unmodifiable(_previousRates);
  
  /// Fetch latest exchange rates from API
  Future<void> fetchLatestRates() async {
    try {
      // Load cached rates first
      await _loadCachedRates();
      
      // Check if we already fetched today
      final today = DateTime.now();
      if (_lastFetchDate != null &&
          _lastFetchDate!.year == today.year &&
          _lastFetchDate!.month == today.month &&
          _lastFetchDate!.day == today.day &&
          _rates.isNotEmpty) {
        return; // Already fetched today
      }
      
      // Fetch from API
      final response = await http.get(
        Uri.parse('$_baseUrl?base=$_baseCurrency'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['rates'] != null) {
          // Save previous rates for comparison
          if (_rates.isNotEmpty) {
            _previousRates = Map.from(_rates);
          }
          
          // Parse new rates
          final ratesData = data['rates'] as Map<String, dynamic>;
          _rates = ratesData.map((key, value) => 
            MapEntry(key, (value as num).toDouble())
          );
          
          _lastFetchDate = today;
          await _cacheRates();
        }
      }
    } catch (e) {
      // Use cached rates on error
      if (_rates.isEmpty) {
        await _loadCachedRates();
      }
      // If still empty, use fallback rates
      if (_rates.isEmpty) {
        _loadFallbackRates();
      }
    }
  }
  
  /// Convert amount from USD to target currency
  double convertFromBase(double amountInUsd, String targetCurrency) {
    if (targetCurrency == _baseCurrency) return amountInUsd;
    final rate = _rates[targetCurrency] ?? 1.0;
    return amountInUsd * rate;
  }
  
  /// Convert amount from source currency to USD
  double convertToBase(double amount, String sourceCurrency) {
    if (sourceCurrency == _baseCurrency) return amount;
    final rate = _rates[sourceCurrency] ?? 1.0;
    if (rate == 0) return amount;
    return amount / rate;
  }
  
  /// Convert between any two currencies
  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    final amountInUsd = convertToBase(amount, from);
    return convertFromBase(amountInUsd, to);
  }
  
  /// Get rate change percentage for a currency
  double? getRateChange(String currency) {
    if (!_rates.containsKey(currency) || !_previousRates.containsKey(currency)) {
      return null;
    }
    final current = _rates[currency]!;
    final previous = _previousRates[currency]!;
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }
  
  /// Get rate for a currency
  double getRate(String currency) {
    return _rates[currency] ?? 1.0;
  }
  
  Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final ratesJson = prefs.getString(_ratesKey);
      if (ratesJson != null) {
        final ratesData = json.decode(ratesJson) as Map<String, dynamic>;
        _rates = ratesData.map((key, value) => 
          MapEntry(key, (value as num).toDouble())
        );
      }
      
      final previousJson = prefs.getString(_previousRatesKey);
      if (previousJson != null) {
        final previousData = json.decode(previousJson) as Map<String, dynamic>;
        _previousRates = previousData.map((key, value) => 
          MapEntry(key, (value as num).toDouble())
        );
      }
      
      final dateStr = prefs.getString(_rateDateKey);
      if (dateStr != null) {
        _lastFetchDate = DateTime.tryParse(dateStr);
      }
    } catch (_) {
      // Ignore cache load errors
    }
  }
  
  Future<void> _cacheRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ratesKey, json.encode(_rates));
      await prefs.setString(_previousRatesKey, json.encode(_previousRates));
      await prefs.setString(_rateDateKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Ignore cache save errors
    }
  }
  
  /// Fallback rates when API/cache unavailable (approximate rates)
  void _loadFallbackRates() {
    _rates = {
      'USD': 1.0,
      'INR': 83.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 149.0,
      'AUD': 1.53,
      'CAD': 1.36,
      'CHF': 0.88,
      'CNY': 7.24,
      'SGD': 1.34,
    };
  }
}
