import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Deutschi';
}

class AppColors {
  static const Color articleDie = Colors.pink;
  static const Color articleDas = Colors.yellow;
  static const Color articleDer = Colors.blue;

  static Color getArticleColor(String? article) {
    switch (article) {
      case 'Die':
        return articleDie;
      case 'Das':
        return articleDas;
      case 'Der':
        return articleDer;
      default:
        return Colors.grey.shade200;
    }
  }
}
