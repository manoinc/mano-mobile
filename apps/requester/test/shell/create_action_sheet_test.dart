import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/shell/create_action_sheet.dart';
import 'package:mano_ui/mano_ui.dart';

/// Raises the sheet the same way [NavShell] does -- through [showManoSheet],
/// not by pumping the sheet's content directly -- so `Navigator.pop()` in its
/// close button has a route to pop.
Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ManoTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ManoPrimaryButton(
              label: 'open',
              onPressed: () => showManoSheet<void>(
                context: context,
                builder: (_) => const CreateActionSheet(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('the create action sheet', () {
    testWidgets('commits to what posting a job looks like', (tester) async {
      await _open(tester);

      expect(find.text('¿Qué necesitas hacer?'), findsOneWidget);
      expect(find.text('Publicar un trabajo'), findsOneWidget);
      // A live primary button, not a disabled row -- it reads as "not built
      // yet", not "not built". Disambiguated from the host's own trigger
      // button, which is also a `FilledButton`.
      final postButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Publicar un trabajo'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(postButton.enabled, isTrue);
    });

    testWidgets('shows a category for every kind of job Home offers', (
      tester,
    ) async {
      await _open(tester);

      for (final label in [
        'Limpieza',
        'Plomería',
        'Electricidad',
        'Pintura',
        'Jardinería',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('tapping a category shows the stub notice', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Plomería'));
      await tester.pumpAndSettle();

      expect(find.text('Muy pronto'), findsOneWidget);
    });

    testWidgets('tapping "Publicar un trabajo" shows the stub notice', (
      tester,
    ) async {
      await _open(tester);

      await tester.tap(find.text('Publicar un trabajo'));
      await tester.pumpAndSettle();

      expect(find.text('Muy pronto'), findsOneWidget);
    });
  });
}
