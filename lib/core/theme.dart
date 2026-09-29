import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Beyaz + mavi paleti. Anlamsal renkler (tazelik) `dates.dart`'taki
/// [Freshness] içinde durur.
abstract final class AppColors {
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const blueLight = Color(0xFF3B82F6);
  static const blueTint = Color(0xFFEFF5FF);
  static const blueTint2 = Color(0xFFDBE8FE);

  static const background = Color(0xFFF5F8FD);
  static const surface = Colors.white;
  static const border = Color(0xFFE4EAF3);
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF131C2E);
  static const darkBorder = Color(0xFF223049);

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const _radius = 18.0;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? AppColors.darkBackground : AppColors.background;
  final surface = dark ? AppColors.darkSurface : AppColors.surface;
  final border = dark ? AppColors.darkBorder : AppColors.border;
  final text = dark ? const Color(0xFFE2E8F0) : AppColors.text;
  final muted = dark ? const Color(0xFF94A3B8) : AppColors.textMuted;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: brightness,
  ).copyWith(
    primary: dark ? AppColors.blueLight : AppColors.blue,
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xFF1E3A8A) : AppColors.blueTint2,
    onPrimaryContainer: dark ? const Color(0xFFDBEAFE) : AppColors.blueDark,
    secondaryContainer: dark ? const Color(0xFF1E2B45) : AppColors.blueTint,
    onSecondaryContainer: dark ? const Color(0xFFBFDBFE) : AppColors.blueDark,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: muted,
    surfaceContainerLowest: surface,
    surfaceContainerLow: dark ? const Color(0xFF162036) : const Color(0xFFF8FAFE),
    surfaceContainer: dark ? const Color(0xFF18233A) : AppColors.blueTint,
    surfaceContainerHigh: dark ? const Color(0xFF1C2842) : const Color(0xFFEAF1FD),
    surfaceContainerHighest: dark ? const Color(0xFF22304D) : const Color(0xFFE2EBFA),
    outline: border,
    outlineVariant: border,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    brightness: brightness,
  );
  final textTheme = base.textTheme.apply(bodyColor: text, displayColor: text).copyWith(
        headlineMedium: base.textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5),
        headlineSmall: base.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3),
        titleLarge: base.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: text),
        titleMedium: base.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: text),
        titleSmall: base.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: text),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: muted),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape.copyWith(side: BorderSide(color: border)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? scheme.primary : muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.primary : muted,
          )),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: buttonShape,
        side: BorderSide(color: border, width: 1.5),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1A2540) : const Color(0xFFF1F5FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5)),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStatePropertyAll(BorderSide(color: border)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      constraints: const BoxConstraints(minHeight: 52),
      hintStyle: WidgetStatePropertyAll(TextStyle(color: muted)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: scheme.primary,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
      secondaryLabelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      checkmarkColor: Colors.white,
      showCheckmark: false,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: border,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF1E293B) : AppColors.text,
      actionTextColor: const Color(0xFF93C5FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primaryContainer,
    ),
  );
}
