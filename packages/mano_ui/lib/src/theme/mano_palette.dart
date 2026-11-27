import 'package:flutter/material.dart';

import 'mano_theme.dart';

/// [ManoColors] by name, with light and dark values; read via `context.palette`.
@immutable
class ManoPalette extends ThemeExtension<ManoPalette> {
  const ManoPalette({
    required this.ink,
    required this.muted,
    required this.faint,
    required this.sand,
    required this.stone,
    required this.clay,
    required this.paper,
  });

  /// Primary text and strong fills.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Tertiary text, placeholders, disabled.
  final Color faint;

  /// Raised surfaces.
  final Color sand;

  /// Dividers, quiet borders, placeholders.
  final Color stone;

  /// Links and secondary emphasis.
  final Color clay;

  /// The page, and text drawn on an [ink] fill.
  final Color paper;

  /// Flame is the same in both modes.
  Color get flame => ManoColors.flame;

  static const light = ManoPalette(
    ink: ManoColors.ink,
    muted: ManoColors.muted,
    faint: ManoColors.faint,
    sand: ManoColors.sand,
    stone: ManoColors.stone,
    clay: ManoColors.clay,
    paper: Colors.white,
  );

  static const dark = ManoPalette(
    ink: ManoColors.sand,
    muted: Color(0xFFC2BCB8),
    faint: Color(0xFF948E8B),
    sand: Color(0xFF24211F),
    stone: Color(0xFF302C2A),
    clay: Color(0xFFE38B5E),
    paper: Color(0xFF191716),
  );

  @override
  ManoPalette copyWith({
    Color? ink,
    Color? muted,
    Color? faint,
    Color? sand,
    Color? stone,
    Color? clay,
    Color? paper,
  }) => ManoPalette(
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    faint: faint ?? this.faint,
    sand: sand ?? this.sand,
    stone: stone ?? this.stone,
    clay: clay ?? this.clay,
    paper: paper ?? this.paper,
  );

  @override
  ManoPalette lerp(ManoPalette? other, double t) {
    if (other == null) return this;
    return ManoPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      stone: Color.lerp(stone, other.stone, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
    );
  }
}

extension ManoPaletteContext on BuildContext {
  /// The palette for the current theme; light if the theme has none.
  ManoPalette get palette =>
      Theme.of(this).extension<ManoPalette>() ?? ManoPalette.light;
}
