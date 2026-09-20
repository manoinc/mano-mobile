import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  group('the reveal', () {
    test('never animates the m', () {
      // The app-open sequence has been showing the m since the native splash.
      // Fading it in again would undo that continuity.
      for (final progress in [0.0, 0.3, 0.7, 1.0]) {
        expect(ManoWordmark.glyphProgress(0, progress), 1);
      }
    });

    test('brings the letters in left to right', () {
      // At any moment mid-reveal, a letter is never further along than the one
      // before it -- that ordering is the whole effect.
      for (final progress in [0.1, 0.25, 0.4, 0.6, 0.8]) {
        final a = ManoWordmark.glyphProgress(1, progress);
        final n = ManoWordmark.glyphProgress(2, progress);
        final o = ManoWordmark.glyphProgress(3, progress);

        expect(a, greaterThanOrEqualTo(n), reason: 'at $progress');
        expect(n, greaterThanOrEqualTo(o), reason: 'at $progress');
      }
    });

    test('starts with the m alone and finishes with the whole word', () {
      expect(ManoWordmark.glyphProgress(1, 0), 0);
      expect(ManoWordmark.glyphProgress(3, 0), 0);

      for (var i = 0; i < 4; i++) {
        expect(ManoWordmark.glyphProgress(i, 1), 1, reason: 'glyph $i');
      }
    });

    test('overlaps the letters rather than queueing them', () {
      // Three letters arriving strictly one after another reads as a machine
      // typing. They should be in flight together.
      const midway = 0.4;
      final inFlight = [
        for (var i = 1; i < 4; i++) ManoWordmark.glyphProgress(i, midway),
      ].where((t) => t > 0 && t < 1);

      expect(inFlight.length, greaterThanOrEqualTo(2));
    });
  });

  group('layout', () {
    testWidgets('takes its width from the artwork, at any height', (tester) async {
      for (final height in [24.0, 40.0, 96.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ManoTheme.light(),
            home: Center(child: ManoWordmark(height: height)),
          ),
        );

        final size = tester.getSize(find.byType(ManoWordmark));
        expect(size.height, height);
        expect(
          size.width / size.height,
          closeTo(kManoWordmarkSize.aspectRatio, 0.001),
        );
      }
    });

    testWidgets('holds the same box throughout the reveal', (tester) async {
      // If the lockup resized as letters arrived, everything laid out beneath
      // it would shuffle for a second. The letters move; the box does not.
      late Size first;

      for (final progress in [0.0, 0.5, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ManoTheme.light(),
            home: Center(child: ManoWordmark(progress: progress, height: 48)),
          ),
        );

        final size = tester.getSize(find.byType(ManoWordmark));
        if (progress == 0.0) {
          first = size;
        } else {
          expect(size, first, reason: 'at $progress');
        }
      }
    });

    testWidgets('fits a narrow phone without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(ManoSpacing.lg),
              child: Align(
                alignment: Alignment.topLeft,
                child: ManoWordmark(height: 34),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(ManoWordmark)).width,
        lessThan(320 - 2 * ManoSpacing.lg),
      );
    });

    testWidgets('announces the product name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(theme: ManoTheme.light(), home: const ManoWordmark()),
      );

      expect(find.bySemanticsLabel('Mano'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the monogram', () {
    testWidgets('takes its width from the artwork', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: const Center(child: ManoMonogram(height: 64)),
        ),
      );

      final size = tester.getSize(find.byType(ManoMonogram));
      expect(size.height, 64);
      expect(
        size.width / size.height,
        closeTo(kManoMonogramSize.aspectRatio, 0.001),
      );
    });
  });

  group('the arch motif', () {
    testWidgets('is decoration: no touches, no semantics', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: Stack(
            children: [
              GestureDetector(
                // Opaque, or the bare SizedBox registers no hit area and the
                // test would pass for the wrong reason.
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped = true,
                child: const SizedBox.expand(),
              ),
              const Positioned.fill(child: ManoArchMotif()),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(ManoArchMotif), warnIfMissed: false);
      expect(tapped, isTrue, reason: 'the motif must not swallow the tap');
      expect(find.bySemanticsLabel('Mano'), findsNothing);
    });

    testWidgets('bleeds past its box rather than fitting inside it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: const SizedBox(
            width: 400,
            height: 400,
            child: ManoArchMotif(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(const ManoArchMotif().widthFactor, greaterThan(1));
    });
  });
}
