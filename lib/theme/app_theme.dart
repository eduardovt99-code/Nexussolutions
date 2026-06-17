import 'package:flutter/material.dart';

/// TAJO — El sistema operativo de la reforma.
/// Identidad: amarillo de seguridad, negro y blanco.
class AppTheme {
  // ── Marca ──
  static const Color brandYellow = Color(0xFFFFD200);
  static const Color brandBlack = Color(0xFF000000);
  static const Color brandYellowLight = Color(0xFFFFE566);
  /// Dorado oscuro legible sobre fondo blanco (texto, enlaces, iconos).
  static const Color brandYellowDark = Color(0xFF9A7500);
  /// Fondo suave para chips y badges amarillos.
  static const Color brandYellowMuted = Color(0xFFFFF3C4);

  // ── Base ──
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFF141416); // Re-mapped to dark
  static const Color surfaceLight = Color(0xFF1E1E20); // Re-mapped to dark

  static const Color textPrimary = pureWhite; // Re-mapped to white
  static const Color textSecondary = Color(0xFF8E8E93);

  // Alias heredados (mapeados a la nueva paleta)
  static const Color accentCyan = brandYellow;
  static const Color accentPurple = brandBlack;
  static const Color deepCyan = brandYellow;
  static const Color deepPurple = brandBlack;

  // ── Estados ──
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Alias heredados para compatibilidad
  static const Color pureBlack = textPrimary;
  static const Color darkGrey = Color(0xFFE8E8E8);
  static const Color neonGreen = successGreen;
  static const Color primaryAction = brandBlack;
  static const Color backgroundDark = Color(0xFF141416);
  static const Color surfaceDark = Color(0xFF1E1E20);
  static const Color borderDark = Color(0xFF2C2C2E);
  static const Color textMutedDark = Color(0xFF8E8E93);

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [brandYellow, brandYellowLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepGradient = LinearGradient(
    colors: [brandBlack, Color(0xFF333333)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [brandBlack, Color(0xFF1A1A1A)],
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
        return pureWhite;
      case 'active':
        return brandYellow;
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
        return brandYellow;
      case 'invoiced':
        return brandBlack;
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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: brandYellow,
      splashFactory: InkRipple.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: brandYellow,
        secondary: brandYellow,
        surface: surfaceLight,
        error: errorRed,
        onPrimary: brandBlack,
        onSecondary: brandBlack,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brandYellow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: brandBlack,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: brandBlack),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5),
        displayMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter', letterSpacing: -0.3),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, fontFamily: 'Inter'),
        labelLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlack,
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
          side: const BorderSide(color: Color(0xFFD0D0D0)),
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
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: brandYellow, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brandBlack,
        contentTextStyle: const TextStyle(color: pureWhite, fontFamily: 'Inter'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Logo de marca: casco de obra + TAJO.
class TajoLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;
  final EdgeInsets padding;

  const TajoLogo({
    super.key,
    this.iconSize = 28,
    this.fontSize = 22,
    this.showLabel = true,
    this.backgroundColor = AppTheme.brandYellow,
    this.foregroundColor = AppTheme.brandBlack,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  /// Logo sobre fondo amarillo (tarjeta de marca).
  const TajoLogo.onYellow({
    super.key,
    this.iconSize = 44,
    this.fontSize = 44,
    this.showLabel = true,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  })  : backgroundColor = AppTheme.brandYellow,
        foregroundColor = AppTheme.brandBlack;

  /// Logo compacto para AppBar (sin caja de fondo).
  const TajoLogo.inline({
    super.key,
    this.iconSize = 18,
    this.fontSize = 20,
    this.showLabel = true,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.all(6),
  })  : backgroundColor = AppTheme.brandYellow,
        foregroundColor = AppTheme.brandBlack;

  /// Logo sobre fondo negro.
  const TajoLogo.onBlack({
    super.key,
    this.iconSize = 28,
    this.fontSize = 22,
    this.showLabel = true,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  })  : backgroundColor = AppTheme.brandBlack,
        foregroundColor = AppTheme.pureWhite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        'assets/images/TAJO.png',
        height: fontSize > iconSize ? fontSize * 1.2 : iconSize * 1.2,
        fit: BoxFit.contain,
      ),
    );
  }
}
