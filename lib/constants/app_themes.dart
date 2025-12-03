import 'package:flutter/material.dart';

class AppThemes {
  // --- Color Palette ---
  // A deep, authoritative green often found in board logos and outfields
  static const Color _boardGreen = Color(0xFF006A4E);
  // A vibrant red representing the leather ball
  static const Color _cricketBallRed = Color(0xFFD32F2F);
  // A rich gold for trophies and premium accents
  static const Color _trophyGold = Color(0xFFFFD700);
  // Neon green for the "Rubber Ball" / Gully cricket feel
  static const Color _tennisBallGreen = Color(0xFFD2E718);
  // Clean white for statistical clarity
  static const Color _stumpWhite = Color(0xFFFFFFFF);
  // Light grey for backgrounds to reduce eye strain
  static const Color _pitchGrey = Color(0xFFF5F5F5);

  static ThemeData cricketBoardTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',

    // --- Color Scheme ---
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _boardGreen,
      onPrimary: _stumpWhite,
      primaryContainer: Color(0xFF004D38),
      onPrimaryContainer: _stumpWhite,
      secondary: _cricketBallRed,
      onSecondary: _stumpWhite,
      tertiary: _trophyGold,
      onTertiary: Colors.black,
      error: Color(0xFFBA1A1A),
      onError: _stumpWhite,
      surface: _stumpWhite,
      onSurface: Colors.black87,
    ),

    scaffoldBackgroundColor: _pitchGrey,

    // --- AppBar Theme ---
    appBarTheme: const AppBarTheme(
      backgroundColor: _boardGreen,
      foregroundColor: _stumpWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: _stumpWhite,
      ),
      iconTheme: IconThemeData(color: _stumpWhite),
    ),

    // --- Navigation Bar Theme (Modern M3) ---
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _stumpWhite,
      elevation: 3,
      shadowColor: Colors.black26,
      height: 70, // Slightly taller for modern look
      indicatorColor: _tennisBallGreen, // Rubber ball color for selection
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
              color: _boardGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12
          );
        }
        return TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 12
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: _boardGreen, size: 26);
        }
        return IconThemeData(color: Colors.grey.shade600, size: 24);
      }),
    ),

    // --- Card Theme ---
    cardTheme: CardThemeData(
      color: _stumpWhite,
      elevation: 2,
      shadowColor: _boardGreen.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),

    // --- Button Themes ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _boardGreen,
        foregroundColor: _stumpWhite,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _boardGreen,
        side: const BorderSide(color: _boardGreen, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _cricketBallRed,
      foregroundColor: _stumpWhite,
      elevation: 6,
    ),

    // --- Tab Bar Theme ---
    tabBarTheme: const TabBarThemeData(
      labelColor: _trophyGold,
      unselectedLabelColor: Color(0xB3FFFFFF),
      indicatorColor: _trophyGold,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),

    // --- Input Decoration ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _stumpWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _boardGreen, width: 2),
      ),
      prefixIconColor: _boardGreen,
      labelStyle: TextStyle(color: Colors.grey.shade700),
    ),

    // --- Text Theme ---
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: _boardGreen,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: _boardGreen,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      bodyLarge: TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.black54,
        fontSize: 14,
      ),
    ),

    // --- Chip Theme ---
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      labelStyle: const TextStyle(color: Colors.black87),
      secondarySelectedColor: _boardGreen,
      secondaryLabelStyle: const TextStyle(color: _stumpWhite),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
  );
}