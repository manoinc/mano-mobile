import 'package:flutter/material.dart';

import 'mano_palette.dart';
export 'mano_palette.dart';
import 'mano_typography.dart';

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
///
/// The brand really only draws two: a 14px corner on anything that holds
/// content, and a full round on anything you press. `sm`, `md` and `lg` are the
/// Material-shaped leftovers they replaced, kept for the widgets still on them.
abstract final class ManoRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;

  /// Fields, cards, sheets, notices -- `--mano-radius` in the stylesheet.
  static const double card = 14;

  /// Buttons. Larger than any button is tall, which is how a radius becomes a
  /// pill and stays one at every height.
  static const double pill = 999;
}

/// Mano's brand colours.
///
/// Taken from the landing site's design system rather than re-picked, so the
/// app and the marketing page are the same orange. Wherever sign-in ends up
/// happening, it should be the same orange too.
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

  /// Darkens photos under overlaid controls; the same in both modes.
  static const Color scrim = ink;
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
    final p = isLight ? ManoPalette.light : ManoPalette.dark;

    // Seeded schemes harmonise a whole palette from one colour, which is right
    // for the incidental surfaces. But the brand's own values are then pinned
    // back over the roles that carry it: a tonally-derived orange is not the
    // orange on the landing page or the login screen, and the near-miss is
    // more noticeable than a mismatch would be.
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
        .copyWith(
          primary: ManoColors.flame,
          onPrimary: Colors.white,
          secondary: p.clay,
          surface: p.paper,
          onSurface: p.ink,
          onSurfaceVariant: p.muted,
          outline: p.faint,
          outlineVariant: p.stone,
          surfaceTint: Colors.transparent,
          surfaceContainerLowest: p.paper,
          surfaceContainerLow: p.sand,
          surfaceContainer: p.sand,
          surfaceContainerHigh: p.stone,
          surfaceContainerHighest: p.stone,
          secondaryContainer: p.stone,
          onSecondaryContainer: p.ink,
          tertiaryContainer: isLight
              ? const Color(0xFFF1E3D6)
              : const Color(0xFF3A2D24),
          onTertiaryContainer: isLight
              ? const Color(0xFF6B3A1B)
              : const Color(0xFFEBCDB4),
          inverseSurface: p.ink,
          onInverseSurface: p.paper,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.paper,
      extensions: [p],
      fontFamily: ManoTypography.fontFamily,
      textTheme: ManoTypography.textTheme(),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ManoRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: ManoTypography.textTheme().labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      chipTheme: ChipThemeData(backgroundColor: scheme.surfaceContainerHighest),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ManoRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}
