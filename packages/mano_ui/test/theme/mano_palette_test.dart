import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', ManoTheme.light()),
    ('dark', ManoTheme.dark()),
  ]) {
    group('$name palette', () {
      final p = theme.extension<ManoPalette>()!;

      test('text stays readable on the page and on raised surfaces', () {
        for (final ground in [p.paper, p.sand]) {
          expect(_contrast(p.ink, ground), greaterThanOrEqualTo(7));
          expect(_contrast(p.muted, ground), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.faint, ground), greaterThanOrEqualTo(3));
          expect(_contrast(p.clay, ground), greaterThanOrEqualTo(3));
        }
      });

      test('paper reads on an ink fill, as on a selected chip', () {
        expect(_contrast(p.paper, p.ink), greaterThanOrEqualTo(7));
      });

      test('the page is the scheme surface', () {
        expect(theme.colorScheme.surface, p.paper);
        expect(theme.colorScheme.onSurface, p.ink);
      });
    });
  }

  test('light palette is the brand palette', () {
    final p = ManoTheme.light().extension<ManoPalette>()!;
    expect(p.ink, ManoColors.ink);
    expect(p.muted, ManoColors.muted);
    expect(p.sand, ManoColors.sand);
    expect(p.paper, Colors.white);
  });

  testWidgets('context.palette follows the theme', (tester) async {
    late ManoPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.dark(),
        home: Builder(
          builder: (context) {
            seen = context.palette;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.ink, isNot(ManoColors.ink));
  });
}
