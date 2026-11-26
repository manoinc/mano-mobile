import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child, {bool still = false}) => MaterialApp(
  theme: ManoTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Scaffold(body: child),
  ),
);

double _opacity(WidgetTester tester) =>
    tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(ManoSkeleton),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

void main() {
  group('ManoSkeleton', () {
    testWidgets('pulses while animations are on', (tester) async {
      await tester.pumpWidget(_host(const ManoSkeleton(height: 12)));
      final start = _opacity(tester);
      await tester.pump(ManoMotion.skeleton ~/ 2);

      expect(_opacity(tester), isNot(start));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('is static with disableAnimations', (tester) async {
      await tester.pumpWidget(_host(const ManoSkeleton(height: 12), still: true));
      final start = _opacity(tester);
      await tester.pump(ManoMotion.skeleton ~/ 2);

      expect(_opacity(tester), start);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('is labelled Cargando and sized as asked', (tester) async {
      await tester.pumpWidget(_host(const ManoSkeleton(width: 80, height: 12)));

      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
      expect(tester.getSize(find.byType(ManoSkeleton)), const Size(80, 12));
    });

    testWidgets('circle is square and round', (tester) async {
      await tester.pumpWidget(_host(const ManoSkeleton.circle(size: 40)));

      expect(tester.getSize(find.byType(ManoSkeleton)), const Size(40, 40));
    });
  });

  group('ManoSkeletonList', () {
    testWidgets('draws N rows under one Cargando label', (tester) async {
      await tester.pumpWidget(_host(const ManoSkeletonList(rows: 4)));

      expect(find.byType(ManoSkeleton), findsNWidgets(4 * 3));
      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    });

    testWidgets('does not overflow at 360dp wide', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const ManoSkeletonList()));

      expect(tester.takeException(), isNull);
    });
  });
}
