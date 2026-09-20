// The generated logo is the one thing in `mano_ui` nobody can eyeball in a
// diff, so these tests stand in for reading it: they assert the properties the
// rest of the package relies on, not the coordinates themselves.
//
// Note what is deliberately not used here: `Path.getBounds()`. Skia returns the
// control-point hull from it, which on this artwork sits up to 0.76 outside the
// ink. Laying the logo out from that would leave it floating slightly inside
// whatever box it was given -- visible the moment it has to line up with a
// native splash drawn from the same file. The generator solves each cubic for
// its turning points instead, and the constants it emits are the authority.
// These tests check that claim against points Skia actually puts on the curve.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

/// Sampling lands near an extremum, not on it, so a measured edge may fall this
/// far short of the declared one.
const double _reach = 0.5;

/// Generated coordinates are rounded to three decimals; nothing may exceed the
/// declared box by more than that rounding.
const double _overshoot = 0.01;

void main() {
  group('the wordmark', () {
    test('is four glyphs, left to right', () {
      expect(kManoWordmarkGlyphs.length, 4);
      expect(kManoWordmarkGlyphExtents.length, 4);

      for (var i = 1; i < kManoWordmarkGlyphExtents.length; i++) {
        final (previousLeft, previousRight) = kManoWordmarkGlyphExtents[i - 1];
        final (left, right) = kManoWordmarkGlyphExtents[i];

        expect(previousLeft, lessThan(previousRight));
        expect(right, greaterThan(left));
        expect(
          left,
          greaterThan(previousRight),
          reason: 'glyph $i must start after glyph ${i - 1} ends; the opening '
              'animation reveals them in this order and would otherwise tear a '
              'letter in half',
        );
      }
    });

    test('fills its declared box, and nothing spills out of it', () {
      _expectFills(manoWordmark(), Offset.zero & kManoWordmarkSize);
    });

    test('has a counter in a, o and the m, and none in n', () {
      // Contour counts are what `PathFillType.nonZero` needs to be right about:
      // if a redraw ever merged a letter's counter into its outline, the glyph
      // would fill solid, and this is the cheapest place to notice.
      expect(
        [for (final glyph in kManoWordmarkGlyphs) glyph().computeMetrics().length],
        [2, 2, 1, 2],
      );
    });

    test('draws each glyph across exactly the extent it advertises', () {
      for (var i = 0; i < kManoWordmarkGlyphs.length; i++) {
        final (left, right) = kManoWordmarkGlyphExtents[i];
        final measured = _inkBounds(kManoWordmarkGlyphs[i]());

        expect(measured.left, closeTo(left, _reach), reason: 'glyph $i left');
        expect(measured.right, closeTo(right, _reach), reason: 'glyph $i right');
        expect(measured.top, greaterThanOrEqualTo(-_overshoot));
        expect(
          measured.bottom,
          lessThanOrEqualTo(kManoWordmarkSize.height + _overshoot),
        );
      }
    });
  });

  group('the monogram', () {
    test('fills its declared box, and nothing spills out of it', () {
      _expectFills(manoMonogram(), Offset.zero & kManoMonogramSize);
    });

    test("shares the wordmark m's proportions closely enough to cross-fade", () {
      // The native splash draws the monogram; the opening animation draws the
      // wordmark's m. They are different drawings, so the handoff only reads as
      // one mark for as long as their aspects agree.
      final monogram = kManoMonogramSize.width / kManoMonogramSize.height;
      final (left, right) = kManoWordmarkGlyphExtents[0];
      final m = (right - left) / kManoWordmarkSize.height;

      expect((monogram - m).abs() / m, lessThan(0.005));
    });
  });
}

void _expectFills(Path path, Rect declared) {
  final measured = _inkBounds(path);

  expect(measured.left, closeTo(declared.left, _reach));
  expect(measured.top, closeTo(declared.top, _reach));
  expect(measured.right, closeTo(declared.right, _reach));
  expect(measured.bottom, closeTo(declared.bottom, _reach));

  expect(measured.left, greaterThanOrEqualTo(declared.left - _overshoot));
  expect(measured.top, greaterThanOrEqualTo(declared.top - _overshoot));
  expect(measured.right, lessThanOrEqualTo(declared.right + _overshoot));
  expect(measured.bottom, lessThanOrEqualTo(declared.bottom + _overshoot));
}

/// The bounds of points Skia actually places on the curve, as opposed to the
/// control hull `Path.getBounds()` reports.
Rect _inkBounds(Path path) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;

  for (final metric in path.computeMetrics()) {
    // Roughly a sample every quarter unit, which on artwork 1400 units wide is
    // dense enough to land within `_reach` of any turning point.
    final steps = math.max(64, (metric.length * 4).ceil());
    for (var i = 0; i <= steps; i++) {
      final position =
          metric.getTangentForOffset(metric.length * i / steps)!.position;
      left = math.min(left, position.dx);
      top = math.min(top, position.dy);
      right = math.max(right, position.dx);
      bottom = math.max(bottom, position.dy);
    }
  }
  return Rect.fromLTRB(left, top, right, bottom);
}
