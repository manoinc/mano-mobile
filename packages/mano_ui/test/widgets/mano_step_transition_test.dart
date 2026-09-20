import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

/// Holds the transition mounted and changes only the step, which is how the
/// flow drives it. Remounting the whole tree would lose the direction.
class _Harness extends StatefulWidget {
  const _Harness({required this.start, this.still = false});

  final int start;
  final bool still;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int _index = widget.start;

  static const _labels = ['uno', 'dos', 'tres'];

  void go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ManoTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: widget.still),
      child: Scaffold(
        body: ManoStepTransition(
          index: _index,
          child: Center(
            key: ValueKey(_labels[_index]),
            child: Text(_labels[_index]),
          ),
        ),
      ),
    ),
  );
}

_HarnessState _state(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness));

void main() {
  testWidgets('shows the step it is given', (tester) async {
    await tester.pumpWidget(const _Harness(start: 0));

    expect(find.text('uno'), findsOneWidget);
  });

  testWidgets('going forward brings the next step in from the right', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness(start: 0));
    await tester.pumpAndSettle();

    _state(tester).go(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      tester.getTopLeft(find.text('dos')).dx,
      greaterThan(tester.getTopLeft(find.text('uno')).dx),
      reason: 'the arriving step should be to the right of the leaving one',
    );

    await tester.pumpAndSettle();
    expect(find.text('uno'), findsNothing);
    expect(find.text('dos'), findsOneWidget);
  });

  testWidgets('going back brings the previous step in from the left', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness(start: 1));
    await tester.pumpAndSettle();

    _state(tester).go(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      tester.getTopLeft(find.text('uno')).dx,
      lessThan(tester.getTopLeft(find.text('dos')).dx),
      reason: 'going back should reverse the direction of travel',
    );

    await tester.pumpAndSettle();
    expect(find.text('uno'), findsOneWidget);
  });

  testWidgets('the leaving step drifts rather than matching the arrival', (
    tester,
  ) async {
    // The outgoing step moves a fraction of the incoming one's distance, which
    // is what reads as depth rather than two cards on a conveyor.
    await tester.pumpWidget(const _Harness(start: 0));
    await tester.pumpAndSettle();

    _state(tester).go(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final width = tester.getSize(find.byType(ManoStepTransition)).width;
    final arriving = tester.getTopLeft(find.text('dos')).dx;
    final leaving = tester.getTopLeft(find.text('uno')).dx;

    expect(leaving.abs(), lessThan(arriving.abs()));
    expect(leaving.abs(), lessThan(width * 0.5));
  });

  testWidgets('arrives in one frame when animations are off', (tester) async {
    await tester.pumpWidget(const _Harness(start: 0, still: true));
    await tester.pumpAndSettle();

    _state(tester).go(1);
    await tester.pump();

    expect(find.text('dos'), findsOneWidget);
    expect(find.text('uno'), findsNothing);
  });
}
