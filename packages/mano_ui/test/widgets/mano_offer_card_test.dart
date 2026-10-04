import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  testWidgets('shows title, pricing model, price and zone', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoOfferCard(
          leading: ManoInitialsAvatar(initials: 'P'),
          title: 'Profesional',
          subtitle: 'Por hora',
          amountLabel: '\$45.000',
          rateLabel: '/hora',
          zone: 'Zona: Chapinero',
        ),
      ),
    );

    expect(find.text('Profesional'), findsOneWidget);
    expect(find.text('Por hora'), findsOneWidget);
    expect(find.byType(ManoPriceTag), findsOneWidget);
    expect(find.text('\$45.000'), findsOneWidget);
    expect(find.text('/hora'), findsOneWidget);
    expect(find.text('Zona: Chapinero'), findsOneWidget);
    expect(find.byType(ManoInitialsAvatar), findsOneWidget);
  });

  testWidgets('renders the optional status and trailing slots', (tester) async {
    var agendado = false;
    await tester.pumpWidget(
      _host(
        ManoOfferCard(
          title: 'Limpieza profunda',
          subtitle: 'Precio fijo',
          amountLabel: '\$120.000',
          rateLabel: 'precio fijo',
          zone: 'Sin zona definida',
          status: const ManoStatusChip(
            label: 'Pausada',
            tone: ManoStatusTone.warning,
          ),
          trailing: ManoTextAction(
            label: 'Agendar',
            onPressed: () => agendado = true,
          ),
        ),
      ),
    );

    expect(find.text('Pausada'), findsOneWidget);
    await tester.tap(find.text('Agendar'));
    expect(agendado, isTrue);
  });

  testWidgets('omits the slots when not given', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoOfferCard(
          title: 'Profesional',
          subtitle: 'Precio fijo',
          amountLabel: '\$80.000',
          rateLabel: 'precio fijo',
          zone: 'Sin zona definida',
        ),
      ),
    );

    expect(find.byType(ManoStatusChip), findsNothing);
    expect(find.byType(ManoTextAction), findsNothing);
  });

  testWidgets('reports a tap anywhere on the card', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _host(
        ManoOfferCard(
          title: 'Profesional',
          subtitle: 'Precio fijo',
          amountLabel: '\$80.000',
          rateLabel: 'precio fijo',
          zone: 'Zona: Usaquén',
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('Zona: Usaquén'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });
}
