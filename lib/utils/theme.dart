import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const Color background = Color(0xFF0e0e0e);
  static const Color surface = Color(0xFF0e0e0e);
  static const Color surfaceDim = Color(0xFF0e0e0e);
  static const Color surfaceContainer = Color(0xFF1a1919);
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerHigh = Color(0xFF201f1f);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  static const Color surfaceBright = Color(0xFF2c2c2c);
  static const Color surfaceVariant = Color(0xFF262626);

  // Neon accents
  static const Color primary = Color(0xFFbc9eff);
  static const Color primaryDim = Color(0xFFad89ff);
  static const Color primaryContainer = Color(0xFFb08dff);
  static const Color primaryFixed = Color(0xFFb08dff);
  static const Color primaryFixedDim = Color(0xFFa37cfa);
  static const Color onPrimary = Color(0xFF3b008a);
  static const Color onPrimaryContainer = Color(0xFF2d006d);
  static const Color onPrimaryFixed = Color(0xFF000000);
  static const Color onPrimaryFixedVariant = Color(0xFF380085);

  static const Color secondary = Color(0xFF52fd98);
  static const Color secondaryDim = Color(0xFF3eee8c);
  static const Color secondaryContainer = Color(0xFF006d39);
  static const Color secondaryFixed = Color(0xFF52fd98);
  static const Color secondaryFixedDim = Color(0xFF3eee8c);
  static const Color onSecondary = Color(0xFF005d30);
  static const Color onSecondaryContainer = Color(0xFFe3ffe5);
  static const Color onSecondaryFixed = Color(0xFF004824);
  static const Color onSecondaryFixedVariant = Color(0xFF006836);

  static const Color tertiary = Color(0xFFffb37f);
  static const Color tertiaryDim = Color(0xFFef924e);
  static const Color tertiaryContainer = Color(0xFFff9f5a);
  static const Color tertiaryFixed = Color(0xFFff9f5a);
  static const Color tertiaryFixedDim = Color(0xFFef924e);
  static const Color onTertiary = Color(0xFF652f00);
  static const Color onTertiaryContainer = Color(0xFF572800);
  static const Color onTertiaryFixed = Color(0xFF341500);
  static const Color onTertiaryFixedVariant = Color(0xFF642f00);

  // Error
  static const Color error = Color(0xFFff6e84);
  static const Color errorDim = Color(0xFFd73357);
  static const Color errorContainer = Color(0xFFa70138);
  static const Color onError = Color(0xFF490013);
  static const Color onErrorContainer = Color(0xFFffb2b9);

  // On colors
  static const Color onSurface = Color(0xFFffffff);
  static const Color onSurfaceVariant = Color(0xFFadaaaa);
  static const Color onBackground = Color(0xFFffffff);

  // Outline
  static const Color outline = Color(0xFF777575);
  static const Color outlineVariant = Color(0xFF494847);

  // Inverse
  static const Color inverseSurface = Color(0xFFfcf8f8);
  static const Color inverseOnSurface = Color(0xFF565554);
  static const Color inversePrimary = Color(0xFF6d45c1);

  // Surface tint
  static const Color surfaceTint = Color(0xFFbc9eff);

  // Glow opacities for shadows
  static const double glowOpacityLow = 0.08;
  static const double glowOpacityMedium = 0.12;
  static const double glowOpacityHigh = 0.20;
  static const double glowOpacityMax = 0.40;

  // Ghost borders
  static const double ghostBorderOpacity = 0.15;

  // Glass card background
  static const Color glassCardBackground = Color(0xB3262626); // 70% opacity
  static const Color glassCardBorder = Color(0x26494847); // 15% opacity
}

class AppTypography {
  static const String headlineFont = 'Manrope';
  static const String bodyFont = 'Manrope';
  static const String labelFont = 'Space Grotesk';

  // Headline styles
  static TextStyle headlineLarge = const TextStyle(
    fontFamily: headlineFont,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMedium = const TextStyle(
    fontFamily: headlineFont,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSmall = const TextStyle(
    fontFamily: headlineFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  // Body styles
  static TextStyle bodyLarge = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static TextStyle bodySmall = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Label styles (Space Grotesk)
  static TextStyle labelLarge = const TextStyle(
    fontFamily: labelFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  static TextStyle labelMedium = const TextStyle(
    fontFamily: labelFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSmall = const TextStyle(
    fontFamily: labelFont,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05,
    color: AppColors.onSurfaceVariant,
  );
}

class AppRadii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
}
