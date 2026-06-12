import 'package:flutter/material.dart';

/// NEXUS — El sistema operativo de la reforma.
/// Identidad: gradiente cian → violeta sobre una base clara y limpia.
class AppTheme {
  // ── Base ──
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F7FB); // gris azulado muy claro
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A); // azul-negro profundo
  static const Color textSecondary = Color(0xFF64748B); // gris pizarra

  // ── Marca (se mantiene la identidad cian/violeta) ──
  static const Color accentCyan = Color(0xFF00E5FF); // brillo de marca (gradientes, glows)
  static const Color accentPurple = Color(0xFF8A2BE2);
  static const Color deepCyan = Color(0xFF0095B5); // cian profundo: legible sobre blanco
  static const Color deepPurple = Color(0xFF6D28D9);

  // ── Estados ──
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Alias heredados para compatibilidad
  static const Color pureBlack = textPrimary;
  static const Color darkGrey = Color(0xFFE2E8F0);
  static const Color neonGreen = successGreen;
  static const Color primaryAction = deepCyan;
  static const Color backgroundDark = backgroundLight;
  static const Color surfaceDark = surfaceLight;

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [accentCyan, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepGradient = LinearGradient(
    colors: [deepCyan, deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Etiquetas de estado de obra.
  static String worksiteStatusLabel(String status) {
    switch (status) {
      case 'quoting':
        return 'PRESUPUESTANDO';
      case 'active':
        return 'EN OBRA';
      case 'completed':
        return 'FINALIZADA';
      default:
        return status.toUpperCase();
    }
  }

  static Color worksiteStatusColor(String status) {
    switch (status) {
      case 'quoting':
        return deepPurple;
      case 'active':
        return deepCyan;
      case 'completed':
        return successGreen;
      default:
        return textSecondary;
    }
  }

  /// Etiquetas de estado de presupuesto/factura.
  static String budgetStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'BORRADOR';
      case 'sent':
        return 'ENVIADO';
      case 'approved':
        return 'FIRMADO';
      case 'invoiced':
        return 'FACTURADO';
      case 'paid':
        return 'COBRADO';
      case 'rejected':
        return 'RECHAZADO';
      default:
        return status.toUpperCase();
    }
  }

  static Color budgetStatusColor(String status) {
    switch (status) {
      case 'draft':
        return textSecondary;
      case 'sent':
        return warningAmber;
      case 'approved':
        return deepCyan;
      case 'invoiced':
        return deepPurple;
      case 'paid':
        return successGreen;
      case 'rejected':
        return errorRed;
      default:
        return textSecondary;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: deepCyan,
      splashFactory: InkRipple.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: deepCyan,
        secondary: deepPurple,
        surface: surfaceLight,
        error: errorRed,
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Color(0xFFE6EAF2)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE6EAF2), thickness: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5),
        displayMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter', letterSpacing: -0.3),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, fontFamily: 'Inter'),
        labelLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepCyan,
          foregroundColor: pureWhite,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, fontFamily: 'Inter', letterSpacing: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: Color(0xFFD6DEE9)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter', letterSpacing: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFFD6DEE9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFFD6DEE9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: deepCyan, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: pureWhite, fontFamily: 'Inter'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
