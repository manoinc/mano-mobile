import 'package:flutter/material.dart';

/// Mano's type.
///
/// Poppins, in three weights, bundled rather than fetched: a login screen is
/// the worst possible place to depend on a font CDN being reachable.
///
/// Headings are tracked in at -0.03em, subheadings at -0.02em, and nothing is
/// ever tracked out. Tracking is computed from each style's own `fontSize`
/// rather than carried as one shared pixel value, since it is meant to be a
/// fraction of the size, not a constant that is only right at one of them.
abstract final class ManoTypography {
  /// Fonts declared by a package are addressed through it, prefix and all.
  /// Spelling this once is the difference between the brand face and a silent
  /// fallback to Roboto.
  static const String fontFamily = 'packages/mano_ui/Poppins';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight extraBold = FontWeight.w800;

  /// Headline tracking, as a fraction of the size. `-0.03em` in the stylesheet.
  static const double _headlineTracking = -0.03;

  /// Subheading tracking. `-0.02em`.
  static const double _titleTracking = -0.02;

  static TextStyle _style(
    double size,
    FontWeight weight, {
    double tracking = 0,
    double height = 1.2,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: size * tracking,
    height: height,
  );

  /// The text theme, in a single colour; `ThemeData` applies the scheme's
  /// `onSurface` over it.
  static TextTheme textTheme() => TextTheme(
    // Reserved for the brand: the wordmark, and a hero's opening line.
    displayLarge: _style(44, extraBold, tracking: _headlineTracking, height: 1),
    displayMedium: _style(38, extraBold, tracking: _headlineTracking, height: 1),
    displaySmall: _style(32, extraBold, tracking: _headlineTracking, height: 1.05),

    headlineLarge: _style(30, extraBold, tracking: _headlineTracking, height: 1.1),
    headlineMedium: _style(27, semiBold, tracking: _titleTracking, height: 1.2),
    headlineSmall: _style(24, semiBold, tracking: _titleTracking, height: 1.2),

    titleLarge: _style(20, semiBold, tracking: _titleTracking, height: 1.25),
    titleMedium: _style(17, semiBold, height: 1.3),
    titleSmall: _style(15, semiBold, height: 1.3),

    bodyLarge: _style(16, regular, height: 1.45),
    bodyMedium: _style(15, regular, height: 1.45),
    bodySmall: _style(13, regular, height: 1.4),

    // Sentence case, never tracked-out caps.
    labelLarge: _style(15, semiBold, height: 1.2),
    labelMedium: _style(13, semiBold, height: 1.2),
    labelSmall: _style(12, semiBold, height: 1.2),
  );
}
