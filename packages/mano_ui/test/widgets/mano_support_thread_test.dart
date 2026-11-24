import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

final _at = DateTime(2026, 11, 2, 9, 30);

Future<void> _pump(
  WidgetTester tester, {
  Future<bool> Function(String)? onSend,
  Future<void> Function()? onRefresh,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(
      body: ManoSupportThread(
        entries: [
          ManoChatEntry(
            id: '0',
            text: 'Me cobraron doble',
            sentAt: _at,
            mine: true,
          ),
          ManoChatEntry(id: '1', text: 'Lo revisamos', sentAt: _at),
        ],
        staffLabel: 'Soporte Mano',
        hintText: 'Escribe un mensaje',
        closedNote: 'Solicitud cerrada',
        onRefresh: onRefresh ?? () async {},
        onSend: onSend,
      ),
    ),
  ),
);

void main() {
  testWidgets('labels staff replies only', (tester) async {
    await _pump(tester, onSend: (_) async => true);
    expect(find.text('Soporte Mano'), findsOneWidget);
    expect(find.text('Lo revisamos'), findsOneWidget);
    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });

  testWidgets('without onSend the composer gives way to the note', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(ManoMessageComposer), findsNothing);
    expect(find.text('Solicitud cerrada'), findsOneWidget);
  });

  testWidgets('pulling down refreshes', (tester) async {
    var refreshed = 0;
    await _pump(tester, onRefresh: () async => refreshed++);
    await tester.fling(find.text('Lo revisamos'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(refreshed, 1);
  });
}
