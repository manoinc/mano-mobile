import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the outline action', () {
    testWidgets('the flame tone draws border and label in the primary', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoOutlineButton(
            label: 'Iniciar sesión',
            tone: ManoOutlineTone.flame,
            onPressed: () {},
          ),
        ),
      );

      final style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      final states = <WidgetState>{};
      expect(style.side!.resolve(states)!.color, ManoColors.flame);
      expect(style.foregroundColor!.resolve(states), ManoColors.flame);
    });

    testWidgets('carries its label and calls back', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoOutlineButton(label: 'Iniciar sesión', onPressed: () => taps++),
        ),
      );

      expect(find.text('Iniciar sesión'), findsOneWidget);

      await tester.tap(find.byType(ManoOutlineButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('shows a spinner and stops taking taps while busy', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoOutlineButton(
            label: 'Iniciar sesión',
            busy: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.text('Iniciar sesión'), findsNothing);
      expect(find.byType(ManoLoader), findsOneWidget);

      await tester.tap(find.byType(ManoOutlineButton));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('a null callback disables it without the spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ManoOutlineButton(label: 'Iniciar sesión', onPressed: null),
        ),
      );

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.byType(ManoLoader), findsNothing);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
        isFalse,
      );
    });
  });

  group('the branded action', () {
    testWidgets('shows the mark it was handed beside the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoBrandButton(
            label: 'Continuar con Google',
            leading: const SizedBox(key: Key('mark'), width: 18, height: 18),
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.byKey(const Key('mark')), findsOneWidget);
    });

    testWidgets('stays legible on both themes', (tester) async {
      // A white fill with a `stone` border is a light-theme idea. On the dark
      // theme it would be a near-white slab, so both have to come from the
      // scheme instead.
      for (final theme in [ManoTheme.light(), ManoTheme.dark()]) {
        await tester.pumpWidget(
          _host(
            ManoBrandButton(
              label: 'Continuar con Google',
              leading: const SizedBox(width: 18, height: 18),
              onPressed: () {},
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final label = tester.widget<Text>(find.text('Continuar con Google'));
        final ground = theme.colorScheme.surface.computeLuminance();
        final ink = label.style!.color!.computeLuminance();

        expect(
          (ink - ground).abs(),
          greaterThan(0.3),
          reason: 'the label disappears into the button',
        );
      }
    });
  });

  group('the corner action', () {
    testWidgets('takes only the width its label needs', (tester) async {
      // The full-width quiet button demands infinite width and cannot sit in a
      // header row; this is the one that can.
      await tester.pumpWidget(
        _host(
          Row(
            children: [
              const Spacer(),
              ManoTextAction(label: 'Omitir', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ManoTextAction)).width, lessThan(200));
    });

    testWidgets('calls back, and keeps a thumb-sized target', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(ManoTextAction(label: 'Ahora no', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Ahora no'));
      await tester.pump();

      expect(taps, 1);
      expect(
        tester.getSize(find.byType(ManoTextAction)).height,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('press feedback', () {
    testWidgets('is shared by every button rather than copied', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ManoPrimaryButton(label: 'Registrarse', onPressed: () {}),
              ManoOutlineButton(label: 'Iniciar sesión', onPressed: () {}),
              ManoBrandButton(
                label: 'Continuar con Google',
                leading: const SizedBox(width: 18, height: 18),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ManoPressScale), findsNWidgets(3));
    });

    testWidgets('takes a press down and lets it back up', (tester) async {
      await tester.pumpWidget(
        _host(const ManoPressScale(enabled: true, child: Text('x'))),
      );

      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

      expect(scale(), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('x')),
      );
      await tester.pump();
      expect(scale(), lessThan(1));

      await gesture.up();
      await tester.pump();
      expect(scale(), 1);
    });

    testWidgets('stays still when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const ManoPressScale(enabled: false, child: Text('x'))),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('x')),
      );
      await tester.pump();

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
    });
  });
}
