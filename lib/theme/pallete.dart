import 'package:flutter/material.dart';

class Pallete {
  // Dark theme colors
  static const Color darkBackgroundColor = Colors.black;
  static const Color darkSearchBarColor = Color.fromRGBO(32, 35, 39, 1);
  static const Color darkCardColor = Color.fromRGBO(16, 16, 16, 1);
  static const Color darkTextColor = Colors.white;
  static const Color darkSecondaryTextColor = Colors.grey;
  
  // Light theme colors
  static const Color lightBackgroundColor = Colors.white;
  static const Color lightSearchBarColor = Color.fromRGBO(239, 243, 244, 1);
  static const Color lightCardColor = Colors.white;
  static const Color lightTextColor = Colors.black;
  static const Color lightSecondaryTextColor = Color.fromRGBO(83, 100, 113, 1);
  
  // Common colors (same for both themes)
  static const Color blueColor = Color.fromRGBO(29, 155, 240, 1);
  static const Color redColor = Color.fromRGBO(249, 25, 127, 1);
  static const Color yellowColor = Color.fromRGBO(255, 204, 0, 1);
  static const Color greenColor = Color.fromRGBO(0, 186, 124, 1);
  
  // Legacy colors (for backward compatibility)
  static const Color backgroundColor = darkBackgroundColor;
  static const Color searchBarColor = darkSearchBarColor;
  static const Color whiteColor = Colors.white;
  static const Color greyColor = Colors.grey;
  
  // Dynamic colors based on theme
  static Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackgroundColor : lightBackgroundColor;
  }
  
  static Color getCardColor(bool isDark) {
    return isDark ? darkCardColor : lightCardColor;
  }
  
  static Color getTextColor(bool isDark) {
    return isDark ? darkTextColor : lightTextColor;
  }
  
  static Color getSecondaryTextColor(bool isDark) {
    return isDark ? darkSecondaryTextColor : lightSecondaryTextColor;
  }
  
  static Color getSearchBarColor(bool isDark) {
    return isDark ? darkSearchBarColor : lightSearchBarColor;
  }
  
  static Color getBorderColor(bool isDark) {
    return isDark ? Colors.grey[800]! : Colors.grey[300]!;
  }
}