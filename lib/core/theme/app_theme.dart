import 'package:flutter/material.dart';
import 'package:liburan_create/core/theme/app_layout.dart';

@immutable
class HabitBrandPalette extends ThemeExtension<HabitBrandPalette> {
  const HabitBrandPalette({
    required this.primaryAction,
    required this.completed,
    required this.pending,
    required this.missed,
    required this.inactive,
  });

  final Color primaryAction;
  final Color completed;
  final Color pending;
  final Color missed;
  final Color inactive;

  static const HabitBrandPalette fallback = HabitBrandPalette(
    primaryAction: Color(0xFF3B7BD6),
    completed: Color(0xFF16A34A),
    pending: Color(0xFFF59E0B),
    missed: Color(0xFFD97706),
    inactive: Color(0xFF6B7280),
  );

  @override
  HabitBrandPalette copyWith({
    Color? primaryAction,
    Color? completed,
    Color? pending,
    Color? missed,
    Color? inactive,
  }) {
    return HabitBrandPalette(
      primaryAction: primaryAction ?? this.primaryAction,
      completed: completed ?? this.completed,
      pending: pending ?? this.pending,
      missed: missed ?? this.missed,
      inactive: inactive ?? this.inactive,
    );
  }

  @override
  HabitBrandPalette lerp(ThemeExtension<HabitBrandPalette>? other, double t) {
    if (other is! HabitBrandPalette) {
      return this;
    }
    return HabitBrandPalette(
      primaryAction:
          Color.lerp(primaryAction, other.primaryAction, t) ?? primaryAction,
      completed: Color.lerp(completed, other.completed, t) ?? completed,
      pending: Color.lerp(pending, other.pending, t) ?? pending,
      missed: Color.lerp(missed, other.missed, t) ?? missed,
      inactive: Color.lerp(inactive, other.inactive, t) ?? inactive,
    );
  }
}

extension HabitSemanticColors on ThemeData {
  HabitBrandPalette get habitColors =>
      extension<HabitBrandPalette>() ?? HabitBrandPalette.fallback;
}

extension HabitSemanticContext on BuildContext {
  HabitBrandPalette get habitColors => Theme.of(this).habitColors;
}

class AppTheme {
  static ThemeData light() {
    const HabitBrandPalette brand = HabitBrandPalette(
      primaryAction: Color(0xFF1A5BAD),
      completed: Color(0xFF3F6353),
      pending: Color(0xFFF59E0B),
      missed: Color(0xFFBA1A1A),
      inactive: Color(0xFF585F6A),
    );
    const Color scaffold = Color(0xFFF8F9FF);
    const Color card = Colors.white;

    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: brand.primaryAction,
      brightness: Brightness.light,
    );
    final ColorScheme colorScheme = base.copyWith(
      primary: brand.primaryAction,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEFF4FF),
      onPrimaryContainer: const Color(0xFF001B3E),
      secondary: brand.inactive,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDCE3F0),
      onSecondaryContainer: const Color(0xFF151C25),
      tertiary: brand.completed,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF577C6B),
      onTertiaryContainer: const Color(0xFFF5FFF7),
      error: brand.missed,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
      surface: card,
      onSurface: const Color(0xFF121C2A),
      surfaceContainerHighest: const Color(0xFFD9E3F6),
      outline: const Color(0xFF727783),
      outlineVariant: const Color(0xFFC2C6D3),
    );

    const Color primaryText = Color(0xFF111827);
    const Color secondaryText = Color(0xFF6B7280);
    final TextTheme baseText = Typography.blackMountainView;
    final TextTheme textTheme = baseText.copyWith(
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.2,
        color: primaryText,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -0.15,
        color: primaryText,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0,
        color: primaryText,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: primaryText,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: primaryText,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: primaryText,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: primaryText,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: secondaryText,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: secondaryText,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const <ThemeExtension<dynamic>>[brand],
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffold,
      splashColor: colorScheme.primary.withValues(alpha: 0.06),
      highlightColor: colorScheme.primary.withValues(alpha: 0.03),
      hoverColor: colorScheme.primary.withValues(alpha: 0.03),
      focusColor: colorScheme.primary.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        iconColor: colorScheme.onSurface.withValues(alpha: 0.72),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.24),
            width: 1,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.fab),
        ),
        extendedTextStyle: textTheme.labelLarge,
        elevation: 0,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.standard,
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          maximumSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.transparent, width: 0),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurface.withValues(alpha: 0.74);
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return Colors.transparent;
          }),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.62),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.88),
            width: 1.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.3);
          }
          return colorScheme.outline.withValues(alpha: 0.22);
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll<double>(0),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.92);
          }
          return colorScheme.onSurface.withValues(alpha: 0.72);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.42)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }
}
