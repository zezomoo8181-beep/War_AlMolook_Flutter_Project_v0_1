import 'package:flutter/material.dart';

class GameColors {
  static const background = Color(0xFF101A1B);
  static const panel = Color(0xFF1B2928);
  static const panelLight = Color(0xFF263A36);
  static const gold = Color(0xFFE7B85C);
  static const goldDark = Color(0xFFB98232);
  static const green = Color(0xFF77B66D);
  static const text = Color(0xFFF3EBDD);
  static const muted = Color(0xFFB0BDB4);
  static const danger = Color(0xFFE47766);
}

ThemeData buildGameTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: GameColors.background,
  colorScheme: const ColorScheme.dark(
    primary: GameColors.gold,
    secondary: GameColors.green,
    surface: GameColors.panel,
    error: GameColors.danger,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: GameColors.background,
    foregroundColor: GameColors.text,
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: GameColors.panel,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: GameColors.panelLight,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
