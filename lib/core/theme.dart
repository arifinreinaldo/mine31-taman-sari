import 'package:flutter/material.dart';

abstract class AppTheme {
  static const _seedColor = Color(0xFF1565C0); // Blue 800

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );
}
