import 'package:flutter/material.dart';

/// Spacing, in multiples of four.
///
/// A scale rather than free numbers: when every gap is drawn from the same
/// small set, screens built months apart still line up.
abstract final class ManoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii.
abstract final class ManoRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

/// Mano's palette and typography.
///
/// One seed colour, two schemes. Both apps share this so a Solicitante and a
/// Proveedor plainly belong to the same product, and so a change to the brand
/// is one edit rather than two.
abstract final class ManoTheme {
  /// A deep green: the marketplace's promise is competent, unflashy help.
  static const Color seed = Color(0xFF2F6F4E);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ManoRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ManoRadius.md),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ManoRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
