import 'package:flutter/material.dart';

class AppTheme {
  static const Color colorPrimary = Color(0xFF212121);
  static const Color colorPrimaryDark = Color(0xFF121212);
  static const Color colorAccent = Color(0xFFFFC107);
  static const Color colorWhite = Colors.white;
  static const Color colorBackground = Color(0xFF121212);
  static const Color colorSurface = Color(0xFF1E1E1E);
  static const Color colorCard = Color(0xFF2A2A2A);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: colorAccent,
          secondary: colorAccent,
          surface: colorSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: colorWhite,
        ),
        scaffoldBackgroundColor: colorBackground,
        fontFamily: 'Raleway',
        appBarTheme: const AppBarTheme(
          backgroundColor: colorPrimaryDark,
          foregroundColor: colorWhite,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorWhite,
          ),
        ),
        cardTheme: CardTheme(
          color: colorCard,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: colorAccent,
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: colorPrimary,
          selectedItemColor: colorAccent,
          unselectedItemColor: Colors.grey,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colorWhite,
            fontFamily: 'Raleway',
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorWhite,
            fontFamily: 'Raleway',
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorWhite,
            fontFamily: 'Raleway',
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: colorWhite,
            fontFamily: 'Raleway',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: colorWhite,
            fontFamily: 'Raleway',
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontFamily: 'Raleway',
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorPrimary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        dividerColor: colorPrimary,
        iconTheme: const IconThemeData(color: colorWhite),
      );
}

class AppStrings {
  static const String appName = 'PlantPlanet';
  static const String history = 'History';
  static const String library = 'Library';
  static const String maps = 'Maps';
  static const String crops = 'Crops';
  static const String result = 'Result';
  static const String symptoms = 'Symptoms';
  static const String comments = 'Comments';
  static const String management = 'Management';
  static const String hear = 'Hear';
  static const String save = 'Save';
  static const String locate = 'Locate';
  static const String delete = 'Delete';
  static const String internetRequired = 'Internet connection is required';
  static const String locationRequired = 'Location permission is required';
  static const String gpsRequired = 'GPS is required';
  static const String cameraRequired = 'Camera permission is required';
  static const String savedSuccessfully = 'Saved successfully';
  static const String deletedSuccessfully = 'Deleted successfully';
  static const String doneSuccessfully = 'Done successfully';
  static const String unknownDisease = 'We cannot recognize this disease';
  static const String historyEmpty = 'Your check history appears here';
  static const String chooseCrop = 'Please choose your crop to continue';
  static const String importImage = 'Import';
  static const String sortBy = 'Sort by';
  static const String name = 'Name';
  static const String category = 'Category';
  static const String crop = 'Crop';
  static const String notSupported = 'This feature is not supported on your device';
  static const String languageNotSupported = 'Your language is not supported';
  static const String somethingWrong = 'Something went wrong, please try again';
  static const String firestoreLibrary = 'library';
  static const String firestoreCrops = 'crops';
}