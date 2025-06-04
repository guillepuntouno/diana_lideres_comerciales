import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData temaDiana = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  textTheme: GoogleFonts.poppinsTextTheme(),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFDE1327), // rojo institucional
  ),
  useMaterial3: true,
);
