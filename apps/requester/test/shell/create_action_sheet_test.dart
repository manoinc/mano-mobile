import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/shell/create_action_sheet.dart';
import 'package:mano_ui/mano_ui.dart';

/// Raises the sheet the same way [NavShell] does -- through [showManoSheet],
/// not by pumping the sheet's content directly -- so `Navigator.pop()` in its
/// close button has a route to pop.
Future<void> _open(
  WidgetTester tester, {
  ValueChanged<String?>? onPublish,
}) async {
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
                builder: (_) =>
                    CreateActionSheet(onPublish: onPublish ?? (_) {}),
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
      expect(find.text('Publicar proyecto'), findsOneWidget);
      // Disambiguated from the host's own trigger, also a `FilledButton`.
      final postButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Publicar proyecto'),
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

    testWidgets('tapping a category publishes with it preselected', (
      tester,
    ) async {
      final picked = <String?>[];
      await _open(tester, onPublish: picked.add);

      await tester.tap(find.text('Plomería'));
      await tester.pumpAndSettle();

      expect(picked, ['plumbing']);
    });

    testWidgets('"Publicar proyecto" publishes with no category', (
      tester,
    ) async {
      final picked = <String?>[];
      await _open(tester, onPublish: picked.add);

      await tester.tap(find.text('Publicar proyecto'));
      await tester.pumpAndSettle();

      expect(picked, [null]);
    });
  });
}
