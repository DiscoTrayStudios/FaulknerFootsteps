import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A custom theme for the app
// Color.fromARGB(255, 107, 79, 79) - appbar?
// Color.fromARGB(255, 72, 52, 52)- text colors?
// (255, 255, 243, 228) - light cream. text and card?
//const Color.fromARGB(255, 238, 214, 196) - background?\
final ThemeData faulknerFootstepsTheme = ThemeData(
    colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 255, 243, 228),
        onPrimary: Color.fromARGB(255, 107, 79, 79),
        secondary: Color.fromARGB(255, 72, 52, 52),
        onSecondary: Color.fromARGB(255, 255, 243, 228),
        error: Colors.red,
        onError: Colors.white,
        surface: Color.fromARGB(255, 238, 214, 196),
        onSurface: Color.fromARGB(255, 62, 50, 50),
        outline: Color.fromARGB(255, 176, 133, 133)),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 72, 52, 52),
      actionsIconTheme:
          IconThemeData(color: Color.fromARGB(255, 255, 243, 228)),
      iconTheme: IconThemeData(color: Color.fromARGB(255, 255, 243, 228)),
      titleTextStyle: GoogleFonts.ultra(
        textStyle: const TextStyle(color: Color.fromARGB(255, 255, 243, 228)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color.fromARGB(255, 72, 52, 52),
        selectedItemColor: Color.fromARGB(255, 238, 214, 196),
        unselectedItemColor: Color.fromARGB(200, 238, 214, 196)),
    //cardTheme: CardThemeData(color: Color.fromARGB(255, 255, 243, 228)),

    textTheme: TextTheme(
        //display

        //headline
        // for site titles
        headlineMedium: GoogleFonts.ultra(
            textStyle: TextStyle(
                // color: Color.fromARGB(255, 72, 52, 52),
                fontSize: 32.0,
                fontWeight: FontWeight.bold)),

        // for description titles
        headlineSmall: GoogleFonts.ultra(
            textStyle: TextStyle(
                // color: Color.fromARGB(255, 72, 52, 52),
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        bodyLarge: GoogleFonts.ultra(fontSize: 18),

        //body
        // for basic text
        bodyMedium: GoogleFonts.rakkas(
            textStyle: TextStyle(
                // color: Color.fromARGB(255, 107, 79, 79),
                fontSize: 20)),

        // for filter chips
        bodySmall: GoogleFonts.ultra(fontSize: 14),

        //label
        labelMedium: GoogleFonts.ultra(
          fontSize: 12,
        )),
    iconTheme: IconThemeData());
