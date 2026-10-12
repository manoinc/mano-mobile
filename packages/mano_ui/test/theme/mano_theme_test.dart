import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  group('typography', () {
    test('resolves the packaged family, not a silent fallback to Roboto', () {
      // The `packages/<name>/` prefix is the whole difference between the brand
      // face and Roboto, and nothing about a missing font throws -- it just
      // renders. So it is asserted rather than trusted.
      final textTheme = ManoTheme.light().textTheme;

      for (final style in [
        textTheme.displayLarge,
        textTheme.headlineLarge,
        textTheme.titleMedium,
        textTheme.bodyMedium,
        textTheme.labelLarge,
      ]) {
        expect(style!.fontFamily, 'packages/mano_ui/Poppins');
      }
    });

    test('tracks headings in proportionally, never out', () {
      final textTheme = ManoTheme.light().textTheme;

      // -0.03em on the display and headline ranks, -0.02em on titles, computed
      // from each style's own size rather than shared as one pixel value.
      expect(
        textTheme.headlineLarge!.letterSpacing,
        closeTo(textTheme.headlineLarge!.fontSize! * -0.03, 0.001),
      );
      expect(
        textTheme.displayLarge!.letterSpacing,
        closeTo(textTheme.displayLarge!.fontSize! * -0.03, 0.001),
      );
      expect(
        textTheme.titleLarge!.letterSpacing,
        closeTo(textTheme.titleLarge!.fontSize! * -0.02, 0.001),
      );

      for (final style in [
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.labelLarge,
      ]) {
        expect(style!.letterSpacing, lessThanOrEqualTo(0));
      }
    });

    test('reserves extra bold for the brand ranks', () {
      final textTheme = ManoTheme.light().textTheme;

      expect(textTheme.displayLarge!.fontWeight, FontWeight.w800);
      expect(textTheme.headlineLarge!.fontWeight, FontWeight.w800);
      expect(textTheme.headlineMedium!.fontWeight, FontWeight.w600);
      expect(textTheme.bodyMedium!.fontWeight, FontWeight.w400);
    });
  });

  group('shape', () {
    test('makes the primary action a pill', () {
      // The landing page and the login page both draw it fully round. A 12px
      // corner is the Material default this replaced.
      for (final theme in [ManoTheme.light(), ManoTheme.dark()]) {
        expect(theme.filledButtonTheme.style!.shape!.resolve({}),
            isA<StadiumBorder>());
      }
    });

    test('gives content surfaces the brand corner', () {
      final shape = ManoTheme.light().cardTheme.shape! as RoundedRectangleBorder;

      expect(
        shape.borderRadius.resolve(TextDirection.ltr).topLeft.x,
        ManoRadius.card,
      );
      expect(ManoRadius.card, 14);
    });
  });

  group('colour', () {
    test('pins flame over the seeded scheme in both brightnesses', () {
      // A tonally-derived orange is not this orange, and the near-miss is worse
      // than no branding at all on the one screen where someone is deciding
      // whether to trust the page.
      for (final theme in [ManoTheme.light(), ManoTheme.dark()]) {
        expect(theme.colorScheme.primary, ManoColors.flame);
        expect(theme.colorScheme.onPrimary, Colors.white);
      }
    });

    test('derives the dark ground from the same tokens as the login theme', () {
      expect(ManoTheme.dark().colorScheme.surface, const Color(0xFF191716));
      expect(ManoTheme.dark().colorScheme.onSurface, ManoColors.sand);
    });
  });

  group('neutral surfaces', () {
    test('light surface containers are warm greys, never tinted pink', () {
      final scheme = ManoTheme.light().colorScheme;
      expect(scheme.surfaceContainerLowest, Colors.white);
      expect(scheme.surfaceContainerLow, ManoColors.sand);
      expect(scheme.surfaceContainer, ManoColors.sand);
      expect(scheme.surfaceContainerHigh, ManoColors.stone);
      expect(scheme.surfaceContainerHighest, ManoColors.stone);
      expect(scheme.surfaceTint, Colors.transparent);
    });

    test('secondary and tertiary containers are neutral and distinguishable', () {
      for (final theme in [ManoTheme.light(), ManoTheme.dark()]) {
        final s = theme.colorScheme;
        for (final c in [s.secondaryContainer, s.tertiaryContainer]) {
          final hsl = HSLColor.fromColor(c);
          final warm = hsl.hue >= 10 && hsl.hue <= 50 || hsl.saturation < 0.15;
          expect(warm, isTrue, reason: 'container $c drifts off the warm palette');
        }
        expect(s.tertiaryContainer, isNot(s.surfaceContainerHighest));
      }
    });

    test('dark containers stay on the warm dark ground', () {
      final s = ManoTheme.dark().colorScheme;
      expect(s.surfaceTint, Colors.transparent);
      expect(s.surfaceContainerHighest, isNot(s.surface));
    });

    test('components drop the elevation tint', () {
      for (final theme in [ManoTheme.light(), ManoTheme.dark()]) {
        expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
        expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerLowest);
        expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
        expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.chipTheme.backgroundColor, theme.colorScheme.surfaceContainerHighest);
        expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
        expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
      }
    });
  });

  group('motion', () {
    test('carries the stylesheet entrance curve', () {
      expect(ManoMotion.entrance, const Cubic(0.23, 1, 0.32, 1));
    });

    test('front-loads the entrance curve', () {
      // The point of cubic-bezier(0.23, 1, 0.32, 1) is that most of the
      // distance is covered early, so the first frame is the fastest and the
      // tail is a settle rather than a slide.
      expect(ManoMotion.entrance.transform(0.25), greaterThan(0.6));
      expect(ManoMotion.entrance.transform(0.5), greaterThan(0.85));
      expect(ManoMotion.entrance.transform(1), closeTo(1, 0.001));
    });
  });
}
