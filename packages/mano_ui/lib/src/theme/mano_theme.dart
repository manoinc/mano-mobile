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

/// Mano's brand colours.
///
/// Taken from the landing site's design system rather than re-picked, so the
/// app, the marketing page and the Keycloak login screen are the same orange.
/// A user who signs in should not notice a seam.
abstract final class ManoColors {
  /// Near-black. Text, rules, and the dark ground.
  static const Color ink = Color(0xFF201E1D);

  /// The one hot surface. Reserved for a single primary action per screen --
  /// its weight is the reason it works, and spending it twice halves it.
  static const Color flame = Color(0xFFFF4A1C);

  /// Flame's quieter relative. Links and secondary emphasis.
  static const Color clay = Color(0xFFC1602E);

  /// Secondary text.
  static const Color muted = Color(0xFF4A4644);

  /// Tertiary text, placeholders, disabled.
  static const Color faint = Color(0xFF8A8481);

  /// Warm off-white for raised surfaces.
  static const Color sand = Color(0xFFF7F5F3);

  /// Dividers and quiet borders.
  static const Color stone = Color(0xFFEDE9E6);
}

/// Mano's palette and typography.
///
/// Both apps share this so a Solicitante and a Proveedor plainly belong to the
/// same product, and so a change to the brand is one edit rather than two.
abstract final class ManoTheme {
  /// The brand's accent, and the seed the rest of the scheme derives from.
  static const Color seed = ManoColors.flame;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Seeded schemes harmonise a whole palette from one colour, which is right
    // for the incidental surfaces. But the brand's own values are then pinned
    // back over the roles that carry it: a tonally-derived orange is not the
    // orange on the landing page or the login screen, and the near-miss is
    // more noticeable than a mismatch would be.
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
          primary: ManoColors.flame,
          onPrimary: Colors.white,
          surface: isLight ? Colors.white : const Color(0xFF191716),
          onSurface: isLight ? ManoColors.ink : ManoColors.sand,
          onSurfaceVariant: isLight ? ManoColors.muted : const Color(0xFFC2BCB8),
          outlineVariant: isLight ? ManoColors.stone : const Color(0xFF302C2A),
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
