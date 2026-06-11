import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(brightness: Brightness.light);

  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme : _lightScheme;
    final glass = isDark ? GlassTokens.dark : GlassTokens.light;
    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = _textTheme(
      _withFontFallback(GoogleFonts.plusJakartaSansTextTheme(baseTextTheme)),
      scheme,
    );
    final radius = BorderRadius.circular(20);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: glass.borderColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      primaryColor: scheme.primary,
      textTheme: textTheme,
      pageTransitionsTheme: _reducedPageTransitions,
      extensions: <ThemeExtension<dynamic>>[glass],
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: glass.surfaceColor.withValues(
          alpha: isDark ? 0.55 : 0.62,
        ),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: glass.surfaceColor,
        shadowColor: glass.shadowColor,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: glass.borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: glass.strongSurfaceColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: glass.shadowColor,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: glass.strongSurfaceColor.withValues(
          alpha: isDark ? 0.82 : 0.88,
        ),
        modalBackgroundColor: glass.strongSurfaceColor.withValues(
          alpha: isDark ? 0.82 : 0.88,
        ),
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.32),
        elevation: 12,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: glass.strongSurfaceColor,
        elevation: 10,
        shadowColor: glass.shadowColor,
        surfaceTintColor: Colors.transparent,
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: glass.borderColor),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xEE182033)
            : const Color(0xF7FFFFFF),
        actionTextColor: scheme.tertiary,
        closeIconColor: scheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: glass.shadowColor,
        indicatorColor: scheme.primaryContainer.withValues(
          alpha: isDark ? 0.58 : 0.72,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: selected ? 25 : 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 3,
        backgroundColor: glass.strongSurfaceColor,
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.32);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surfaceContainerHighest.withValues(alpha: 0.28);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primaryContainer.withValues(alpha: 0.58);
          }
          return glass.surfaceColor.withValues(alpha: 0.72);
        }),
        trackOutlineColor: WidgetStatePropertyAll(glass.borderColor),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: glass.surfaceColor,
        hoverColor: glass.highlightColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: scheme.primary,
        suffixIconColor: scheme.onSurfaceVariant,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(scheme, glass),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedButtonStyle(scheme, glass),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(scheme, glass),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(scheme, glass),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurface.withValues(alpha: 0.34);
            }
            return scheme.onSurfaceVariant;
          }),
          overlayColor: WidgetStatePropertyAll(glass.highlightColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glass.surfaceColor,
        selectedColor: scheme.primaryContainer.withValues(
          alpha: isDark ? 0.62 : 0.76,
        ),
        secondarySelectedColor: scheme.secondaryContainer,
        disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        side: BorderSide(color: glass.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        selectedIcon: const Icon(Icons.check_rounded, size: 18),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer.withValues(
                alpha: isDark ? 0.70 : 0.82,
              );
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(color: scheme.primary.withValues(alpha: 0.24));
            }
            return BorderSide(color: glass.borderColor.withValues(alpha: 0.58));
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          overlayColor: WidgetStatePropertyAll(glass.highlightColor),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.72),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static ButtonStyle _filledButtonStyle(ColorScheme scheme, GlassTokens glass) {
    return FilledButton.styleFrom(
      elevation: 0,
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.primary.withValues(alpha: 0.84);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
      overlayColor: WidgetStatePropertyAll(glass.highlightColor),
    );
  }

  static ButtonStyle _elevatedButtonStyle(
    ColorScheme scheme,
    GlassTokens glass,
  ) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      backgroundColor: glass.surfaceColor,
      foregroundColor: scheme.primary,
      surfaceTintColor: Colors.transparent,
      shadowColor: glass.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ).copyWith(overlayColor: WidgetStatePropertyAll(glass.highlightColor));
  }

  static ButtonStyle _outlinedButtonStyle(
    ColorScheme scheme,
    GlassTokens glass,
  ) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(64, 46),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      foregroundColor: scheme.primary,
      backgroundColor: glass.surfaceColor,
      side: BorderSide(color: glass.borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ).copyWith(
      overlayColor: WidgetStatePropertyAll(glass.highlightColor),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.42),
          );
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return BorderSide(color: scheme.primary.withValues(alpha: 0.72));
        }
        return BorderSide(color: glass.borderColor);
      }),
    );
  }

  static ButtonStyle _textButtonStyle(ColorScheme scheme, GlassTokens glass) {
    return TextButton.styleFrom(
      foregroundColor: scheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ).copyWith(overlayColor: WidgetStatePropertyAll(glass.highlightColor));
  }

  static TextTheme _textTheme(TextTheme textTheme, ColorScheme scheme) {
    return textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          displaySmall: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
          headlineLarge: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.14,
          ),
          headlineMedium: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.16,
          ),
          headlineSmall: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.18,
          ),
          titleLarge: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          titleMedium: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.24,
          ),
          titleSmall: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.24,
          ),
          bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.46),
          bodySmall: textTheme.bodySmall?.copyWith(
            height: 1.42,
            color: scheme.onSurfaceVariant,
          ),
          labelLarge: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelMedium: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
  }

  static TextTheme _withFontFallback(TextTheme textTheme) {
    final devanagariFamily = GoogleFonts.notoSansDevanagari().fontFamily;
    final fallback = devanagariFamily == null
        ? null
        : <String>[devanagariFamily];

    TextStyle? withFallback(TextStyle? style) {
      if (style == null || fallback == null) return style;
      return style.copyWith(fontFamilyFallback: fallback);
    }

    return textTheme.copyWith(
      displayLarge: withFallback(textTheme.displayLarge),
      displayMedium: withFallback(textTheme.displayMedium),
      displaySmall: withFallback(textTheme.displaySmall),
      headlineLarge: withFallback(textTheme.headlineLarge),
      headlineMedium: withFallback(textTheme.headlineMedium),
      headlineSmall: withFallback(textTheme.headlineSmall),
      titleLarge: withFallback(textTheme.titleLarge),
      titleMedium: withFallback(textTheme.titleMedium),
      titleSmall: withFallback(textTheme.titleSmall),
      bodyLarge: withFallback(textTheme.bodyLarge),
      bodyMedium: withFallback(textTheme.bodyMedium),
      bodySmall: withFallback(textTheme.bodySmall),
      labelLarge: withFallback(textTheme.labelLarge),
      labelMedium: withFallback(textTheme.labelMedium),
      labelSmall: withFallback(textTheme.labelSmall),
    );
  }
}

class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.surfaceColor,
    required this.strongSurfaceColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.borderColor,
    required this.shadowColor,
    required this.highlightColor,
    required this.blurSigma,
    required this.surfaceOpacity,
    required this.strongOpacity,
    required this.radius,
  });

  final Color surfaceColor;
  final Color strongSurfaceColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color borderColor;
  final Color shadowColor;
  final Color highlightColor;
  final double blurSigma;
  final double surfaceOpacity;
  final double strongOpacity;
  final double radius;

  static const light = GlassTokens(
    surfaceColor: Color(0xFFFFFFFF),
    strongSurfaceColor: Color(0xFFFFFFFF),
    gradientStart: Color(0xF7FFFFFF),
    gradientEnd: Color(0xA8E9F1EC),
    borderColor: Color(0x8FFFFFFF),
    shadowColor: Color(0x2A273043),
    highlightColor: Color(0x1A6B4D8B),
    blurSigma: 20,
    surfaceOpacity: 0.34,
    strongOpacity: 0.48,
    radius: 20,
  );

  static const dark = GlassTokens(
    surfaceColor: Color(0xFF20283A),
    strongSurfaceColor: Color(0xFF182033),
    gradientStart: Color(0xB62B344A),
    gradientEnd: Color(0x7A111827),
    borderColor: Color(0x33FFFFFF),
    shadowColor: Color(0x70000000),
    highlightColor: Color(0x22D8B4FE),
    blurSigma: 22,
    surfaceOpacity: 0.30,
    strongOpacity: 0.44,
    radius: 20,
  );

  @override
  GlassTokens copyWith({
    Color? surfaceColor,
    Color? strongSurfaceColor,
    Color? gradientStart,
    Color? gradientEnd,
    Color? borderColor,
    Color? shadowColor,
    Color? highlightColor,
    double? blurSigma,
    double? surfaceOpacity,
    double? strongOpacity,
    double? radius,
  }) {
    return GlassTokens(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      strongSurfaceColor: strongSurfaceColor ?? this.strongSurfaceColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      highlightColor: highlightColor ?? this.highlightColor,
      blurSigma: blurSigma ?? this.blurSigma,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      strongOpacity: strongOpacity ?? this.strongOpacity,
      radius: radius ?? this.radius,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      strongSurfaceColor: Color.lerp(
        strongSurfaceColor,
        other.strongSurfaceColor,
        t,
      )!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      surfaceOpacity: lerpDouble(surfaceOpacity, other.surfaceOpacity, t),
      strongOpacity: lerpDouble(strongOpacity, other.strongOpacity, t),
      radius: lerpDouble(radius, other.radius, t),
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF5A3E85),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE8DDF8),
  onPrimaryContainer: Color(0xFF24123D),
  secondary: Color(0xFF28666E),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFD6EEF0),
  onSecondaryContainer: Color(0xFF082F34),
  tertiary: Color(0xFF9C6B18),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFE4B8),
  onTertiaryContainer: Color(0xFF3A2400),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFBF8F2),
  onSurface: Color(0xFF1E1A22),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF8F1EA),
  surfaceContainer: Color(0xFFF2ECE5),
  surfaceContainerHigh: Color(0xFFECE5DF),
  surfaceContainerHighest: Color(0xFFE6DFD9),
  onSurfaceVariant: Color(0xFF5A5261),
  outline: Color(0xFF82788B),
  outlineVariant: Color(0xFFD1C7D8),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF332E38),
  onInverseSurface: Color(0xFFF6EFF8),
  inversePrimary: Color(0xFFD8BDFB),
  surfaceTint: Color(0xFF5A3E85),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD8BDFB),
  onPrimary: Color(0xFF2F1551),
  primaryContainer: Color(0xFF4A2C72),
  onPrimaryContainer: Color(0xFFEFE3FF),
  secondary: Color(0xFF8FD6D6),
  onSecondary: Color(0xFF00373A),
  secondaryContainer: Color(0xFF1B4F55),
  onSecondaryContainer: Color(0xFFB8F2F1),
  tertiary: Color(0xFFF2C572),
  onTertiary: Color(0xFF432B00),
  tertiaryContainer: Color(0xFF654000),
  onTertiaryContainer: Color(0xFFFFDEA5),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF10151F),
  onSurface: Color(0xFFF1EEF7),
  surfaceContainerLowest: Color(0xFF0B0F17),
  surfaceContainerLow: Color(0xFF171D2A),
  surfaceContainer: Color(0xFF1B2230),
  surfaceContainerHigh: Color(0xFF252D3D),
  surfaceContainerHighest: Color(0xFF303849),
  onSurfaceVariant: Color(0xFFCFC6D8),
  outline: Color(0xFF988EA2),
  outlineVariant: Color(0xFF4D4558),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE8E0EA),
  onInverseSurface: Color(0xFF302B35),
  inversePrimary: Color(0xFF63448F),
  surfaceTint: Color(0xFFD8BDFB),
);

const _reducedPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoPageTransitionsBuilder(),
    TargetPlatform.iOS: _NoPageTransitionsBuilder(),
    TargetPlatform.macOS: _NoPageTransitionsBuilder(),
    TargetPlatform.windows: _NoPageTransitionsBuilder(),
    TargetPlatform.linux: _NoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
  },
);

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
