import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

const Key _hero = Key('hero');

Widget _host({
  bool animate = true,
  bool ready = true,
  VoidCallback? onFirstFrame,
  bool disableAnimations = false,
}) =>
    MaterialApp(
      theme: ManoTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: ManoOpening(
          animate: animate,
          ready: ready,
          onFirstFrame: onFirstFrame,
          child: const ColoredBox(key: _hero, color: ManoColors.sand),
        ),
      ),
    );

/// The travelling lockup is only in the tree while the sequence is running, so
/// its absence is how a finished opening is recognised.
bool _opening(WidgetTester tester) =>
    tester.any(find.byType(ManoWordmark));

double _letters(WidgetTester tester) =>
    tester.widget<ManoWordmark>(find.byType(ManoWordmark)).progress;

void main() {
  testWidgets('takes the native splash down only once a frame is up',
      (tester) async {
    // Removing it before Flutter has painted shows a blank window between the
    // two. Proof that it has painted: the lockup is laid out and has a size by
    // the time the callback runs. From initState it would not be.
    var removed = 0;
    Size? laidOutAt;

    await tester.pumpWidget(_host(onFirstFrame: () {
      removed++;
      final lockup = find.byType(ManoWordmark);
      if (tester.any(lockup)) laidOutAt = tester.getSize(lockup);
    }));

    expect(removed, 1);
    expect(laidOutAt, isNotNull, reason: 'the lockup was not in the tree yet');
    expect(laidOutAt!.height, ManoLockup.preferredOpeningHeight);

    await tester.pumpAndSettle();
    expect(removed, 1, reason: 'once, not once per frame');
  });

  testWidgets('holds the m alone before the letters start', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(_opening(tester), isTrue);
    expect(_letters(tester), 0, reason: 'the word has not begun arriving');

    await tester.pump(ManoMotion.opening * 0.1);
    expect(_letters(tester), 0);
  });

  testWidgets('brings the letters in, then hands over', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    await tester.pump(ManoMotion.opening * 0.4);
    final midway = _letters(tester);
    expect(midway, greaterThan(0));
    expect(midway, lessThan(1));

    await tester.pump(ManoMotion.opening * 0.3);
    expect(_letters(tester), greaterThan(midway));

    await tester.pumpAndSettle();
    expect(_opening(tester), isFalse, reason: 'the sequence should be over');
    expect(find.byKey(_hero), findsOneWidget);
  });

  testWidgets('waits on the finished lockup rather than opening onto nothing',
      (tester) async {
    await tester.pumpWidget(_host(ready: false));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_opening(tester), isTrue, reason: 'still restoring the session');
    expect(_letters(tester), 1, reason: 'but the word is fully drawn');

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(_opening(tester), isFalse);
  });

  testWidgets('does not replay on a warm resume', (tester) async {
    await tester.pumpWidget(_host(animate: false));
    await tester.pump();

    expect(_opening(tester), isFalse, reason: 'straight to the screen');
    expect(find.byKey(_hero), findsOneWidget);
  });

  testWidgets('lands on the end state when animations are turned off',
      (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump();

    expect(_opening(tester), isFalse);
    expect(find.byKey(_hero), findsOneWidget);
  });

  testWidgets('runs its full length even when there is nothing to wait for',
      (tester) async {
    // A greeting that flashes past is worse than no greeting.
    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump(ManoMotion.opening ~/ 2);

    expect(_opening(tester), isTrue);
  });

  testWidgets('keeps the m where the native splash left it', (tester) async {
    // Android centres the monogram. If the opening centred the whole lockup
    // instead, the mark would jump left the instant Flutter took over -- which
    // is the one seam this whole sequence exists to avoid. The m holds the
    // centre and the letters grow out to the right of it.
    await tester.pumpWidget(_host());
    await tester.pump();

    final screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final lockup = tester.getRect(find.byType(ManoWordmark));

    final (left, right) = kManoWordmarkGlyphExtents.first;
    final mCentreFraction =
        (left + right) / 2 / kManoWordmarkSize.width;
    final mCentre = lockup.left + mCentreFraction * lockup.width;

    expect(mCentre, closeTo(screen / 2, 0.5));
    expect(lockup.height, ManoLockup.preferredOpeningHeight);
  });

  testWidgets('recentres on the whole word once it has arrived', (tester) async {
    await tester.pumpWidget(_host(ready: false));
    await tester.pump();
    await tester.pumpAndSettle();

    final screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final lockup = tester.getRect(find.byType(ManoWordmark));

    expect(lockup.center.dx, closeTo(screen / 2, 0.5));
  });

  testWidgets('fits the lockup on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(ready: false));
    await tester.pump();
    await tester.pumpAndSettle();

    final lockup = tester.getRect(find.byType(ManoWordmark));
    expect(lockup.width, lessThan(320 - ManoLockup.inset));
    expect(lockup.height, lessThan(ManoLockup.preferredOpeningHeight));
  });

  testWidgets('survives a first frame that has no size yet', (tester) async {
    // Flutter's first frame can arrive before the surface has been measured --
    // the engine logs "Width is zero" and lays out at 0x0. The inset alone then
    // makes the fitted lockup height negative, which is an assertion, not a
    // small logo. Caught on a real device, not here, so it is pinned here.
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(ManoLockup.openingHeightFor(0), greaterThanOrEqualTo(0));
    expect(ManoLockup.openingHeightFor(-50), greaterThanOrEqualTo(0));
  });
}
