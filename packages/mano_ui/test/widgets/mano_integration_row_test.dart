import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('the integration row', () {
    testWidgets('shows the leading slot, title and status', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoIntegrationRow(
            leading: const Icon(Icons.calendar_month),
            title: 'Google Calendar',
            status: 'No conectado',
            actionLabel: 'Conectar',
            onAction: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('No conectado'), findsOneWidget);
      expect(find.text('Conectar'), findsOneWidget);
    });

    testWidgets('puts the action flush with the right edge', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoIntegrationRow(
            leading: const Icon(Icons.calendar_month),
            title: 'Google Calendar',
            status: 'No conectado',
            actionLabel: 'Conectar',
            onAction: () {},
          ),
        ),
      );

      final label = tester.getRect(find.text('Conectar'));
      final row = tester.getRect(find.byType(ManoIntegrationRow));
      expect(row.right - label.right, lessThan(ManoSpacing.xs));
    });

    testWidgets('fires the single action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoIntegrationRow(
            leading: const Icon(Icons.calendar_month),
            title: 'Google Calendar',
            status: 'No conectado',
            actionLabel: 'Conectar',
            onAction: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Conectar'));
      expect(taps, 1);
    });

    testWidgets('offers an overflow only when onMore is given', (tester) async {
      var more = 0;
      Widget row({VoidCallback? onMore}) => _host(
        ManoIntegrationRow(
          leading: const Icon(Icons.calendar_month),
          title: 'Google Calendar',
          status: 'Conectado',
          actionLabel: 'Copiar enlace',
          onAction: () {},
          onMore: onMore,
        ),
      );

      await tester.pumpWidget(row());
      expect(find.byTooltip('Más opciones'), findsNothing);

      await tester.pumpWidget(row(onMore: () => more++));
      await tester.tap(find.byTooltip('Más opciones'));
      expect(more, 1);
    });

    testWidgets('a null action disables the button', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoIntegrationRow(
            leading: Icon(Icons.calendar_month),
            title: 'Google Calendar',
            status: 'No conectado',
            actionLabel: 'Conectar',
            onAction: null,
          ),
        ),
      );

      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
    });
  });
}
