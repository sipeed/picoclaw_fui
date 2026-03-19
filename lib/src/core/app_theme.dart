import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  carbon, // Deep Gray / Vibrant Cyan (Modern Dark Minimalist)
  slate, // Slate 950 / Amber (Elegant & Sharp)
  obsidian, // True Black / Subtle White (Extreme Minimalist)
  ebony, // Warm Dark Gray / Gold (Premium Feel)
  nord, // Polar Night / Frost (Soft & Clean)
  sakura, // Dark Rose / Pink (Soft Tech Aesthetic)
}

class AppTheme {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.carbon:
        return _buildTheme(
          primary: const Color(0xFF111111), // Pure Dark
          primaryContainer: const Color(0xFF1A1A1A), // Elevated Neutral
          secondary: const Color(0xFF00E5FF), // Neon Cyan
        );
      case AppThemeMode.slate:
        return _buildTheme(
          primary: const Color(0xFF020617), // Slate 950
          primaryContainer: const Color(0xFF0F172A), // Slate 900
          secondary: const Color(0xFFF59E0B), // Amber 500
        );
      case AppThemeMode.obsidian:
        return _buildTheme(
          primary: const Color(0xFF000000), // OLED Black
          primaryContainer: const Color(0xFF111111), //
          secondary: const Color(0xFFFFFFFF), // Pure White
        );
      case AppThemeMode.ebony:
        return _buildTheme(
          primary: const Color(0xFF0C0C0C), // Warm Deep Ebony
          primaryContainer: const Color(0xFF1A1A1A),
          secondary: const Color(0xFFFACC15), // Gold/Yellow
        );
      case AppThemeMode.nord:
        return _buildTheme(
          primary: const Color(0xFF2E3440), // Nord Polar Night
          primaryContainer: const Color(0xFF3B4252),
          secondary: const Color(0xFF88C0D0), // Frost Blue
        );
      case AppThemeMode.sakura:
        return _buildTheme(
          primary: const Color(
            0xFFAD1457,
          ), // Pink 800 (Sidebar - High contrast vs White text)
          primaryContainer: const Color(
            0xFFFDF2F8,
          ), // Rose 50 (Main Content - Low glare, high clarity)
          secondary: const Color(
            0xFFC2185B,
          ), // Pink 700 (Primary Action/Highlight)
          isDark: false,
        );
    }
  }

  static ThemeData _buildTheme({
    required Color primary,
    required Color primaryContainer,
    required Color secondary,
    bool isDark = true,
  }) {
    // 🎨 2025 Minimalist "Floating Tile" Aesthetic
    final factory = isDark ? FlexThemeData.dark : FlexThemeData.light;

    return factory(
      colors: FlexSchemeColor(
        primary: primary, // Sidebar Background (Major semantic color)
        primaryContainer: primaryContainer, // Main Content Background
        secondary: secondary, // Action / Highlight color
        secondaryContainer: secondary.withAlpha(isDark ? 30 : 50),
        tertiary: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
        appBarColor: primary,
      ),
      scaffoldBackground: primary,
      surface: primaryContainer,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 0,
      subThemesData: FlexSubThemesData(
        blendOnLevel: 0,
        useMaterial3Typography: true,
        inputDecoratorRadius: 8.0,
        navigationRailLabelType: NavigationRailLabelType.all,
        navigationRailIndicatorSchemeColor:
            SchemeColor.onPrimary, // Indicator contrasts with Sidebar
        navigationRailIndicatorOpacity: 1.0,
        navigationRailBackgroundSchemeColor:
            SchemeColor.primary, // Force Rail to use our Primary color
        navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
        navigationRailUnselectedIconSchemeColor: SchemeColor.onPrimary,
        navigationRailMutedUnselectedIcon: true,
        cardRadius: 12,
        cardElevation: 0,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: primary,
        selectedIconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.white,
        ),
        unselectedIconTheme: IconThemeData(
          color: (isDark ? Colors.white : Colors.white).withAlpha(
            ((0.5).clamp(0.0, 1.0) * 255).round(),
          ),
        ),
        selectedLabelTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: (isDark ? Colors.white : Colors.white).withAlpha(
            ((0.5).clamp(0.0, 1.0) * 255).round(),
          ),
        ),
      ),
    );
  }
}
