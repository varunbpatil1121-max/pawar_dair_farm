import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const green = Color(0xFF2C7A4B);
  static const greenDark = Color(0xFF14462B);
  static const leaf = Color(0xFF7BC47F);
  static const cream = Color(0xFFFFF6E6);
  static const sand = Color(0xFFF6F1E7); // page background
  static const line = Color(0xFFEAE3D5); // hairline borders
  static const ink = Color(0xFF1D2A22);
  static const amber = Color(0xFFE9A23B);
  static const sky = Color(0xFF3B8BD9);
  static const rose = Color(0xFFE05A5A);
  static const violet = Color(0xFF8A63D2);
  static const teal = Color(0xFF1E9E9A);

  static const heroGradient = [
    Color(0xFF14462B),
    Color(0xFF2C7A4B),
    Color(0xFF4E9E68),
  ];
}

const appFont = 'Jakarta';

ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    brightness: brightness,
  );
  final scheme = light
      ? base.copyWith(
          primary: AppColors.green,
          surface: AppColors.sand,
          onSurface: AppColors.ink,
          surfaceContainerLowest: Colors.white,
          outlineVariant: AppColors.line,
        )
      : base;
  final cardColor = light ? Colors.white : scheme.surfaceContainer;
  final border = light
      ? AppColors.line
      : scheme.outlineVariant.withValues(alpha: 0.4);

  final text = ThemeData(brightness: brightness).textTheme.apply(
    fontFamily: appFont,
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: appFont,
    colorScheme: scheme,
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: appFont,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: border),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),
    dividerTheme: DividerThemeData(color: border, space: 1),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: border),
      labelStyle: const TextStyle(
        fontFamily: appFont,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: appFont,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: border),
        textStyle: const TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: border),
        backgroundColor: cardColor,
        selectedBackgroundColor: scheme.primaryContainer,
        textStyle: const TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.greenDark,
      foregroundColor: Colors.white,
      elevation: 2,
      extendedTextStyle: const TextStyle(
        fontFamily: appFont,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: appFont,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: const TextStyle(
        fontFamily: appFont,
        fontWeight: FontWeight.w700,
      ),
      dividerColor: border,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: light
          ? AppColors.green.withValues(alpha: 0.14)
          : scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: appFont,
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
  );
}

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _num = NumberFormat('#,##0.##', 'en_IN');

String rupees(num v) => _money.format(v);
String qty(num v) => _num.format(v);
String fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String fmtShortDate(DateTime d) => DateFormat('d MMM').format(d);
String fmtDay(DateTime d) => DateFormat('EEE, d MMM').format(d);
String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);
String fmtMonth(DateTime d) => DateFormat('MMMM yyyy').format(d);

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return fmtShortDate(d);
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
