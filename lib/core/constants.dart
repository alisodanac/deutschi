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

  /// Plain English color name for an article, used in AI image-generation prompts.
  /// Returns null for words without an article (non-nouns).
  static String? getArticleColorName(String? article) {
    switch (article) {
      case 'Die':
        return 'pink';
      case 'Das':
        return 'yellow';
      case 'Der':
        return 'blue';
      default:
        return null;
    }
  }
}
