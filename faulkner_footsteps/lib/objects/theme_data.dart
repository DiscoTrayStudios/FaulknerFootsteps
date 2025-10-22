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
      collapsedIconColor: Color.fromARGB(255, 76, 32, 8),
      collapsedTextColor: Color.fromARGB(255, 76, 32, 8),
      backgroundColor: Color.fromARGB(255, 238, 214, 196),
      iconColor: Color.fromARGB(255, 76, 32, 8),
      textColor: Color.fromARGB(255, 76, 32, 8)),
  textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
          foregroundColor:
              WidgetStatePropertyAll(Color.fromARGB(255, 76, 32, 8)),
          textStyle: WidgetStatePropertyAll(
              TextStyle(color: Color.fromARGB(255, 76, 32, 8))),
          iconColor: WidgetStateProperty.all(Color.fromARGB(255, 76, 32, 8)))),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.all(Color.fromARGB(255, 218, 186, 130)),
          foregroundColor:
              WidgetStateProperty.all(Color.fromARGB(255, 76, 32, 8)),
          textStyle: WidgetStateProperty.all(GoogleFonts.rakkas(
              textStyle: const TextStyle(
                  fontSize: 16, color: Color.fromARGB(255, 76, 32, 8)))))),
  listTileTheme: ListTileThemeData(textColor: Color.fromARGB(255, 76, 32, 8)),
  iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
          iconColor: WidgetStateProperty.all(Color.fromARGB(255, 76, 32, 8)))),
  iconTheme: IconThemeData(color: Color.fromARGB(255, 76, 32, 8)),
  textTheme: TextTheme(
    //  displayMedium: ,

    //  headlineMedium: ,

    titleMedium: GoogleFonts.ultra(
        textStyle: const TextStyle(color: Color.fromARGB(255, 76, 32, 8))),

    bodyMedium: GoogleFonts.rakkas(
        textStyle: const TextStyle(
            fontSize: 18, color: Color.fromARGB(255, 76, 32, 8))),

    bodySmall: GoogleFonts.rakkas(
      textStyle:
          const TextStyle(fontSize: 18, color: Color.fromARGB(255, 76, 32, 8)),
    ),

    // labelMedium: ,
  ),
  inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: Color.fromARGB(255, 76, 32, 8), width: 2.0),
      ),
      labelStyle: GoogleFonts.ultra(
          textStyle: const TextStyle(
              color: Color.fromARGB(255, 76, 32, 8), fontSize: 24))),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color.fromARGB(255, 76, 32, 8),
    selectionColor: Color.fromARGB(255, 76, 32, 8),
    selectionHandleColor: Color.fromARGB(255, 76, 32, 8),
  ),

  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4.0),
    ),
    side: const BorderSide(
      color: Color.fromARGB(255, 72, 52, 52), // Outline when unchecked
      width: 2.0,
    ),
    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color.fromARGB(255, 76, 32, 8); // Checked fill
      }
      return const Color.fromARGB(255, 238, 214, 196); // Unchecked fill
    }),
    checkColor: MaterialStateProperty.all<Color>(
      Color.fromARGB(255, 238, 214, 196), // Checkmark color
    ),
  ),

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
