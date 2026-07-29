import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> map = {
    // French
    'alimentation': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'logement': Icons.home_rounded,
    'loisirs': Icons.sports_esports_rounded,
    'santé': Icons.favorite_rounded,
    'sante': Icons.favorite_rounded,
    'éducation': Icons.school_rounded,
    'education': Icons.school_rounded,
    'autres': Icons.more_horiz_rounded,
    // English
    'food': Icons.restaurant_rounded,
    'housing': Icons.home_rounded,
    'entertainment': Icons.sports_esports_rounded,
    'health': Icons.favorite_rounded,
    'other': Icons.more_horiz_rounded,
    'others': Icons.more_horiz_rounded,
    // Spanish
    'alimentación': Icons.restaurant_rounded,
    'alimentacion': Icons.restaurant_rounded,
    'vivienda': Icons.home_rounded,
    'ocio': Icons.sports_esports_rounded,
    'salud': Icons.favorite_rounded,
    'otros': Icons.more_horiz_rounded,
    'outros': Icons.more_horiz_rounded,
  };

  static IconData forName(String name) =>
      map[name.toLowerCase()] ?? Icons.account_balance_wallet_rounded;
}
