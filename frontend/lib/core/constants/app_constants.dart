import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF312E81);
  static const Color primaryLight = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}

class AppConstants {
  static const String appName = 'Full Stack Web Lab';

  /// Base URL of the FastAPI backend.
  /// Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8765
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8765',
  );

  static const String storageTokenKey = 'fsl_auth_token';
  static const String storageUserKey = 'fsl_auth_user';

  static const int postMaxLength = 280;
  static const int surveySize = 5;
}

/// Per-experiment accent colors used across the dashboard and feature UIs.
class ExperimentPalette {
  static const todo = Color(0xFF4F46E5);
  static const blog = Color(0xFF0EA5E9);
  static const food = Color(0xFFF97316);
  static const classifieds = Color(0xFF10B981);
  static const leave = Color(0xFF8B5CF6);
  static const project = Color(0xFFEC4899);
  static const survey = Color(0xFF14B8A6);
}
