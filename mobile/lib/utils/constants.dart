import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF35A8E7);
  static const Color pink = Color(0xFFFF7DAF);

  static const Color background = Color(0xFFF8F7FD);
  static const Color darkText = Color(0xFF1D1B4B);
  static const Color lightText = Colors.black54;

  static const Color success = Color(0xFF35C2A1);
  static const Color warning = Color(0xFFFF8A65);
  static const Color danger = Colors.redAccent;
}

class AppGradients {
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.secondary,
      AppColors.pink,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      AppColors.primary,
      Color(0xFF8A6BFF),
    ],
  );
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.darkText,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.darkText,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
  );

  static const TextStyle whiteTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static const TextStyle whiteBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );
}

class AppRadius {
  static const double card = 22;
  static const double button = 18;
  static const double large = 28;
}