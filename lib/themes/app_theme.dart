import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blue,
    textTheme: GoogleFonts.robotoTextTheme(),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blueGrey,
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
  );
}
