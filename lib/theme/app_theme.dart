import 'package:flutter/material.dart';
import 'package:twitter_clone/theme/pallete.dart';

class AppTheme {
  // Dark theme
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Pallete.darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Pallete.darkBackgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Pallete.darkTextColor),
      titleTextStyle: TextStyle(
        color: Pallete.darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Pallete.blueColor,
    ),
    cardTheme: CardTheme(
      color: Pallete.darkCardColor,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Pallete.darkTextColor),
      bodyMedium: TextStyle(color: Pallete.darkTextColor),
      titleLarge: TextStyle(color: Pallete.darkTextColor),
      titleMedium: TextStyle(color: Pallete.darkTextColor),
      titleSmall: TextStyle(color: Pallete.darkTextColor),
    ),
    iconTheme: const IconThemeData(color: Pallete.darkTextColor),
    dividerColor: Colors.grey[800],
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Pallete.darkBackgroundColor,
      selectedItemColor: Pallete.darkTextColor,
      unselectedItemColor: Pallete.darkSecondaryTextColor,
    ),
  );

  // Light theme
  static ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Pallete.lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Pallete.lightBackgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Pallete.lightTextColor),
      titleTextStyle: TextStyle(
        color: Pallete.lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Pallete.blueColor,
    ),
    cardTheme: CardTheme(
      color: Pallete.lightCardColor,
      elevation: 1,
      shadowColor: Colors.grey[200],
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Pallete.lightTextColor),
      bodyMedium: TextStyle(color: Pallete.lightTextColor),
      titleLarge: TextStyle(color: Pallete.lightTextColor),
      titleMedium: TextStyle(color: Pallete.lightTextColor),
      titleSmall: TextStyle(color: Pallete.lightTextColor),
    ),
    iconTheme: const IconThemeData(color: Pallete.lightTextColor),
    dividerColor: Colors.grey[300],
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Pallete.lightBackgroundColor,
      selectedItemColor: Pallete.lightTextColor,
      unselectedItemColor: Pallete.lightSecondaryTextColor,
    ),
  );

  // Legacy theme (for backward compatibility)
  static ThemeData theme = darkTheme;
}