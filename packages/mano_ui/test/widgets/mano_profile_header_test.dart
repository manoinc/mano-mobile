import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
      theme: ManoTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('the profile header', () {
    testWidgets('shows the name', (tester) async {
      await tester.pumpWidget(_host(
        ManoProfileHeader(
          name: 'Camila Ríos',
          photoUrl: 'https://example.com/a.png',
          onEdit: () {},
        ),
      ));

      expect(find.text('Camila Ríos'), findsOneWidget);
    });

    testWidgets('calls onEdit exactly once when the edit affordance is tapped',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        ManoProfileHeader(
          name: 'Camila Ríos',
          photoUrl: 'https://example.com/a.png',
          onEdit: () => taps++,
        ),
      ));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('renders the avatar fallback when photoUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(_host(
        ManoProfileHeader(
          name: 'Camila Ríos',
          photoUrl: null,
          onEdit: () {},
        ),
      ));

      expect(find.text('Camila Ríos'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
