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
      surfaceTintColor: Colors.transparent,
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
        bodySmall: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),

        // for filter chips

        //label
        labelLarge: GoogleFonts.ultra(fontSize: 14),
        labelMedium: GoogleFonts.ultra(
          fontSize: 12,
        )),
    iconTheme: IconThemeData());

final ThemeData adminPageTheme = ThemeData(
  // button color: const Color.fromARGB(255, 218, 186, 130)
  // text color?: Color.fromARGB(255, 76, 32, 8)
  colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: const Color.fromARGB(255, 238, 214, 196),
      onPrimary: Color.fromARGB(255, 76, 32, 8), // tertiary
      secondary: const Color.fromARGB(255, 218, 186, 130),
      onSecondary: const Color.fromARGB(255, 238, 214, 196), // primary
      tertiary: Color.fromARGB(
          255, 76, 32, 8), // brownish - red. Mostly used for text
      error: Colors.red,
      onError: Colors.black,
      surface: const Color.fromARGB(255, 219, 196, 166),
      onSurface: const Color.fromARGB(255, 238, 214, 196) // primary
      ),

  expansionTileTheme: ExpansionTileThemeData(
      collapsedIconColor: Colors.deepPurple,
      collapsedTextColor: Color.fromARGB(255, 76, 32, 8),
      backgroundColor: Color.fromARGB(255, 238, 214, 196),
      iconColor: Colors.deepPurple,
      textColor: Color.fromARGB(255, 76, 32, 8)),

  textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.deepPurple),
          textStyle:
              WidgetStatePropertyAll(TextStyle(color: Colors.deepPurple)),
          iconColor: WidgetStateProperty.all(Colors.deepPurple))),

  listTileTheme: ListTileThemeData(textColor: Color.fromARGB(255, 76, 32, 8)),

  textTheme: TextTheme(
      bodySmall: GoogleFonts.rakkas(
          textStyle: const TextStyle(
    fontSize: 18,
  ))).apply(
      bodyColor: Color.fromARGB(255, 76, 32, 8),
      displayColor: Color.fromARGB(255, 76, 32, 8)),
  // elevatedButtonTheme: ElevatedButtonThemeData(
  //     style: ButtonStyle(
  //         backgroundColor:
  //             WidgetStatePropertyAll(adminPageTheme.colorScheme.secondary),
  //         padding: WidgetStatePropertyAll(
  //             EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
  //         textStyle: WidgetStatePropertyAll(GoogleFonts.ultra(
  //             color: adminPageTheme.colorScheme.tertiary))))
);

/// TODO: 
/// Change purple to brown on the buttons
/// edit and delete blurb should be underneath blurb (taking up too much real estate rn)
/// editing text should not be bolded. It should be a defaultish serif font. 
/// Hard to see cancel button. it should have an "outer" button (like the other buttons do)
/// Change white on the buttons to the nice brown. It will be easier to see and read
/// 
