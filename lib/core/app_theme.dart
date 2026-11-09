import 'package:flutter/material.dart';

import 'app_colors.dart';

const FontWeight w4 = FontWeight.w400;
const FontWeight w5 = FontWeight.w500;
const FontWeight w6 = FontWeight.w600;
const FontWeight w7 = FontWeight.w700;

/// Estilo de texto con la tipografía Inter del prototipo.
TextStyle appText(
  double size, {
  FontWeight weight = w4,
  Color color = AppColors.navy,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.white,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: appText(14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
