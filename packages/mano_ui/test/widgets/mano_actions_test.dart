import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
      theme: ManoTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('the primary action', () {
    testWidgets('shows a spinner and stops taking taps while busy', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        ManoPrimaryButton(label: 'Ingresar', busy: true, onPressed: () => taps++),
      ));

      expect(find.text('Ingresar'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(ManoPrimaryButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('distinguishes busy from unavailable', (tester) async {
      // A null callback is "you cannot do this"; busy is "I am already doing
      // it". They must not look the same.
      await tester.pumpWidget(_host(
        const ManoPrimaryButton(label: 'Ingresar', onPressed: null),
      ));

      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).enabled, isFalse);
    });

    testWidgets('fires once when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        ManoPrimaryButton(label: 'Ingresar', onPressed: () => taps++),
      ));

      await tester.tap(find.byType(ManoPrimaryButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('the quiet action', () {
    testWidgets('is type, not a second filled button', (tester) async {
      // Flame only works because a screen spends it once.
      await tester.pumpWidget(_host(
        ManoQuietButton(label: 'Crear cuenta', onPressed: () {}),
      ));

      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('stops taking taps while busy', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        ManoQuietButton(label: 'Crear cuenta', busy: true, onPressed: () => taps++),
      ));

      await tester.tap(find.byType(ManoQuietButton));
      await tester.pump();
      expect(taps, 0);
    });
  });

  group('the sheet', () {
    testWidgets('lists every action, with a rule between them', (tester) async {
      await tester.pumpWidget(_host(
        ManoActionSheet(
          title: 'Entra a Mano',
          onClose: () {},
          actions: [
            ManoSheetAction(label: 'Correo', icon: Icons.mail_outline, onPressed: () {}),
            ManoSheetAction(label: 'Google', onPressed: () {}),
            ManoSheetAction(label: 'Teléfono', onPressed: () {}),
          ],
        ),
      ));

      expect(find.text('Entra a Mano'), findsOneWidget);
      expect(find.byType(ManoOptionRow), findsNWidgets(3));
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('calls back the action that was picked', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(
        ManoActionSheet(
          title: 'Entra a Mano',
          actions: [
            ManoSheetAction(label: 'Correo', onPressed: () => picked = 'correo'),
            ManoSheetAction(label: 'Google', onPressed: () => picked = 'google'),
          ],
        ),
      ));

      await tester.tap(find.text('Google'));
      await tester.pumpAndSettle();
      expect(picked, 'google');
    });

    testWidgets('leaves an unavailable method visible but inert', (tester) async {
      // Google and phone are not configured on the realm yet. Hiding them would
      // lose the shape of the screen; a disabled row with a reason keeps it.
      var taps = 0;
      await tester.pumpWidget(_host(
        ManoActionSheet(
          title: 'Entra a Mano',
          actions: [
            ManoSheetAction(
              label: 'Google',
              detail: 'Muy pronto',
              onPressed: null,
            ),
            ManoSheetAction(label: 'Correo', onPressed: () => taps++),
          ],
        ),
      ));

      expect(find.text('Muy pronto'), findsOneWidget);
      await tester.tap(find.text('Google'));
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('hides the close control when there is no way out', (tester) async {
      await tester.pumpWidget(_host(
        ManoActionSheet(
          title: 'Entra a Mano',
          actions: [ManoSheetAction(label: 'Correo', onPressed: () {})],
        ),
      ));

      expect(find.byTooltip('Cerrar'), findsNothing);
    });

    testWidgets('raises from the bottom and returns what was picked', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ManoPrimaryButton(
                label: 'Ingresar',
                onPressed: () => showManoSheet<String>(
                  context: context,
                  builder: (sheetContext) => ManoActionSheet(
                    title: 'Entra a Mano',
                    onClose: () => Navigator.of(sheetContext).pop(),
                    actions: [
                      ManoSheetAction(
                        label: 'Correo',
                        onPressed: () =>
                            Navigator.of(sheetContext).pop('correo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Entra a Mano'), findsOneWidget);

      await tester.tap(find.text('Correo'));
      await tester.pumpAndSettle();
      expect(find.text('Entra a Mano'), findsNothing);
    });
  });

    testWidgets('never draws a disabled row louder than a live one',
        (tester) async {
      // A disabled row once used ManoColors.stone for its chevron. That is the
      // light theme's divider, so on the dark theme it came out near-white and
      // the two rows nobody could tap were the brightest things on the sheet.
      for (final theme in [ManoTheme.light(), ManoTheme.dark()]) {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ManoActionSheet(
              title: 'Elige cómo entrar',
              actions: [
                ManoSheetAction(label: 'Correo', onPressed: () {}),
                const ManoSheetAction(
                  label: 'Google',
                  detail: 'Muy pronto',
                  onPressed: null,
                ),
              ],
            ),
          ),
        ));
        // MaterialApp animates between themes, so straight after pumping a new
        // one `Theme.of` still reports the old colours. Settling first is the
        // difference between testing this widget and testing AnimatedTheme.
        await tester.pumpAndSettle();

        final chevrons =
            tester.widgetList<Icon>(find.byIcon(Icons.chevron_right)).toList();
        expect(chevrons.length, 2);

        final ground = theme.colorScheme.surface.computeLuminance();
        double contrast(Icon icon) =>
            (icon.color!.computeLuminance() - ground).abs();

        // "Quieter" means closer to the ground it sits on, whichever side of
        // it that is.
        expect(
          contrast(chevrons[1]),
          lessThan(contrast(chevrons[0])),
          reason: 'the disabled chevron stands out more than the live one',
        );
      }
    });
}
