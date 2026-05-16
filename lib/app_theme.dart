import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // ── Brand colors ───────────────────────────────────────────────────────────
  static const Color colorAccent     = Color(0xFF00FF88);
  static const Color colorAccentDark = Color(0xFF00CC66);

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  static const Color colorBackground  = Color(0xFF000000); // true black
  static const Color colorPrimary     = Color(0xFF0A0A0A);
  static const Color colorPrimaryDark = Color(0xFF050505);
  static const Color colorSurface     = Color(0xFF111111);

  // ── Glass card tokens ──────────────────────────────────────────────────────
  static final Color colorCard       = Colors.white.withValues(alpha: 0.07);
  static final Color colorCardBorder = Colors.white.withValues(alpha: 0.10);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color colorWhite   = Colors.white;
  static const Color colorWhite70 = Colors.white70;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: colorAccent,
          secondary: colorAccentDark,
          surface: Color(0xFF111111),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: colorBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: colorAccent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: colorAccent,
          unselectedItemColor: Colors.white54,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16, color: Colors.white, height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14, color: Colors.white70,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerColor: const Color(0xFF1A1A1A),
      );
}

// ── Glassmorphic card widget ───────────────────────────────────────────────────
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── String constants ───────────────────────────────────────────────────────────
class AppStrings {
  static const String appName           = 'Plant';
  static const String history           = 'History';
  static const String library           = 'Library';
  static const String maps              = 'Maps';
  static const String crops             = 'Crops';
  static const String result            = 'Result';
  static const String symptoms          = 'Symptoms';
  static const String comments          = 'Comments';
  static const String management        = 'Management';
  static const String hear              = 'Hear';
  static const String save              = 'Save';
  static const String locate            = 'Locate';
  static const String delete            = 'Delete';
  static const String historyEmpty      = 'Your check history appears here';
  static const String importImage       = 'Import';
  static const String unknownDisease    = 'We cannot recognize this disease';
  static const String savedSuccessfully = 'Saved successfully';
}