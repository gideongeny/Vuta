import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VutaTheme {
  static const Color deepOnyx = Color(0xFF080808);
  static const Color electricSavannah = Color(0xFF00FF85);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepOnyx,
      primaryColor: electricSavannah,
      colorScheme: const ColorScheme.dark(
        primary: electricSavannah,
        surface: deepOnyx,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
