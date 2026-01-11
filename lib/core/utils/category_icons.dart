import 'package:flutter/material.dart';

/// Helper class to map category icon names to Material Icons
class CategoryIcons {
  static const Map<String, IconData> _iconMap = {
    // Food & Dining
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'local_pizza': Icons.local_pizza,
    
    // Transportation
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'train': Icons.train,
    'flight': Icons.flight,
    'local_taxi': Icons.local_taxi,
    'two_wheeler': Icons.two_wheeler,
    
    // Shopping
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'store': Icons.store,
    'local_mall': Icons.local_mall,
    
    // Entertainment
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note,
    'theater_comedy': Icons.theater_comedy,
    
    // Bills & Utilities
    'receipt': Icons.receipt,
    'electric_bolt': Icons.electric_bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone': Icons.phone,
    
    // Healthcare
    'medical_services': Icons.medical_services,
    'local_hospital': Icons.local_hospital,
    'medication': Icons.medication,
    'health_and_safety': Icons.health_and_safety,
    
    // Education
    'school': Icons.school,
    'menu_book': Icons.menu_book,
    'auto_stories': Icons.auto_stories,
    
    // Travel
    'flight_takeoff': Icons.flight_takeoff,
    'hotel': Icons.hotel,
    'luggage': Icons.luggage,
    'beach_access': Icons.beach_access,
    
    // Personal Care
    'spa': Icons.spa,
    'face': Icons.face,
    'self_improvement': Icons.self_improvement,
    
    // Home
    'home': Icons.home,
    'home_repair_service': Icons.home_repair_service,
    'cleaning_services': Icons.cleaning_services,
    
    // Finance
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'payments': Icons.payments,
    
    // Other
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'attach_money': Icons.attach_money,
  };

  /// Get Material icon from icon name string
  static IconData getIcon(String iconName) {
    return _iconMap[iconName] ?? Icons.category;
  }

  /// Get all available icons for category selection
  static List<MapEntry<String, IconData>> getAllIcons() {
    return _iconMap.entries.toList();
  }

  /// Get icons grouped by category
  static Map<String, List<MapEntry<String, IconData>>> getGroupedIcons() {
    return {
      'Food & Dining': [
        MapEntry('restaurant', Icons.restaurant),
        MapEntry('fastfood', Icons.fastfood),
        MapEntry('local_cafe', Icons.local_cafe),
        MapEntry('local_pizza', Icons.local_pizza),
      ],
      'Transportation': [
        MapEntry('directions_car', Icons.directions_car),
        MapEntry('directions_bus', Icons.directions_bus),
        MapEntry('train', Icons.train),
        MapEntry('flight', Icons.flight),
        MapEntry('two_wheeler', Icons.two_wheeler),
      ],
      'Shopping': [
        MapEntry('shopping_bag', Icons.shopping_bag),
        MapEntry('shopping_cart', Icons.shopping_cart),
        MapEntry('store', Icons.store),
      ],
      'Entertainment': [
        MapEntry('movie', Icons.movie),
        MapEntry('sports_esports', Icons.sports_esports),
        MapEntry('music_note', Icons.music_note),
      ],
      'Bills': [
        MapEntry('receipt', Icons.receipt),
        MapEntry('electric_bolt', Icons.electric_bolt),
        MapEntry('water_drop', Icons.water_drop),
        MapEntry('phone', Icons.phone),
      ],
      'Healthcare': [
        MapEntry('medical_services', Icons.medical_services),
        MapEntry('medication', Icons.medication),
      ],
      'Education': [
        MapEntry('school', Icons.school),
        MapEntry('menu_book', Icons.menu_book),
      ],
      'Other': [
        MapEntry('category', Icons.category),
        MapEntry('more_horiz', Icons.more_horiz),
        MapEntry('attach_money', Icons.attach_money),
      ],
    };
  }
}
