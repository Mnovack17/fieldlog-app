import 'package:flutter/material.dart';

/// Design tokens carried over from the Field Log web app: a steel/industrial
/// neutral palette with a safety-orange accent, and status colors that stay
/// distinct from the accent (on-track/ahead/behind/complete/high-safety).
class AppColors {
  static const bg = Color(0xFFEEF1F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunk = Color(0xFFE4E9EC);
  static const border = Color(0xFFCBD4D9);
  static const ink = Color(0xFF172026);
  static const inkSecondary = Color(0xFF4E5D68);
  static const inkMuted = Color(0xFF7E8D97);

  static const accent = Color(0xFFBF4E15);
  static const accentSoft = Color(0xFFFBE3D2);
  static const accentSoftInk = Color(0xFF8A3B0E);

  static const good = Color(0xFF1F8A5F);
  static const goodSoft = Color(0xFFDFF1E8);
  static const info = Color(0xFF2C6E8E);
  static const infoSoft = Color(0xFFDEEBF1);
  static const warn = Color(0xFFB8790E);
  static const warnSoft = Color(0xFFF6E7CC);
  static const crit = Color(0xFFC23B3B);
  static const critSoft = Color(0xFFF8DEDE);
  static const complete = Color(0xFF5B5A9E);
  static const completeSoft = Color(0xFFE6E5F5);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSunk,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.inkSecondary, fontWeight: FontWeight.w600, fontSize: 12.5),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.accent : AppColors.border,
      ),
    ),
  );
}

Color statusColor(String status) {
  switch (status) {
    case 'on_track':
      return AppColors.good;
    case 'ahead':
      return AppColors.info;
    case 'behind':
      return AppColors.warn;
    case 'complete':
      return AppColors.complete;
    default:
      return AppColors.inkMuted;
  }
}

Color statusSoft(String status) {
  switch (status) {
    case 'on_track':
      return AppColors.goodSoft;
    case 'ahead':
      return AppColors.infoSoft;
    case 'behind':
      return AppColors.warnSoft;
    case 'complete':
      return AppColors.completeSoft;
    default:
      return AppColors.surfaceSunk;
  }
}

String statusLabel(String status) {
  switch (status) {
    case 'on_track':
      return 'On Track';
    case 'ahead':
      return 'Ahead';
    case 'behind':
      return 'Behind Schedule';
    case 'complete':
      return 'Complete';
    default:
      return status;
  }
}

Color severityColor(String sev) {
  switch (sev) {
    case 'none':
      return AppColors.good;
    case 'low':
      return AppColors.info;
    case 'medium':
      return AppColors.warn;
    case 'high_safety':
      return AppColors.crit;
    default:
      return AppColors.inkMuted;
  }
}

Color severitySoft(String sev) {
  switch (sev) {
    case 'none':
      return AppColors.goodSoft;
    case 'low':
      return AppColors.infoSoft;
    case 'medium':
      return AppColors.warnSoft;
    case 'high_safety':
      return AppColors.critSoft;
    default:
      return AppColors.surfaceSunk;
  }
}

String severityLabel(String sev) {
  switch (sev) {
    case 'none':
      return 'None';
    case 'low':
      return 'Low';
    case 'medium':
      return 'Medium';
    case 'high_safety':
      return 'High – Safety';
    default:
      return sev;
  }
}
