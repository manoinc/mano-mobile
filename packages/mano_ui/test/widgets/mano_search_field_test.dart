import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the search field', () {
    testWidgets('shows the same default hint as the search pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ManoSearchField(controller: TextEditingController())),
      );

      expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    });

    testWidgets('autofocuses when asked', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoSearchField(controller: TextEditingController(), autofocus: true),
        ),
      );
      await tester.pump();

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);
    });

    testWidgets('reports every change', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(
          ManoSearchField(
            controller: TextEditingController(),
            onChanged: changes.add,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'aseo');

      expect(changes, ['aseo']);
    });

    testWidgets('a clear button appears with text and empties the field', (
      tester,
    ) async {
      final controller = TextEditingController();
      final changes = <String>[];
      await tester.pumpWidget(
        _host(ManoSearchField(controller: controller, onChanged: changes.add)),
      );
      expect(find.byTooltip('Borrar'), findsNothing);

      await tester.enterText(find.byType(TextField), 'aseo');
      await tester.pump();
      await tester.tap(find.byTooltip('Borrar'));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes.last, '');
      expect(find.byTooltip('Borrar'), findsNothing);
    });
  });
}
