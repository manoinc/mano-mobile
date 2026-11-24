import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('shows the radicado, subject and status, and taps through', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: ManoSupportTicketTile(
            number: 'MANO-1',
            subject: 'Cobro doble',
            statusLabel: 'Radicada',
            tone: ManoStatusTone.info,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('MANO-1'), findsOneWidget);
    expect(find.text('Radicada'), findsOneWidget);
    await tester.tap(find.text('Cobro doble'));
    expect(taps, 1);
  });
}
