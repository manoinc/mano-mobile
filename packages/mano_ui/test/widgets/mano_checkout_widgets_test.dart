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
  group('ManoPriceBreakdown', () {
    testWidgets('lists each line, then the total', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoPriceBreakdown(
            title: 'Detalle del precio',
            lines: [('Servicio · precio fijo', r'$120.000')],
            totalLabel: 'Total (COP)',
            totalValue: r'$120.000',
          ),
        ),
      );

      expect(find.text('Detalle del precio'), findsOneWidget);
      expect(find.text('Servicio · precio fijo'), findsOneWidget);
      expect(find.text('Total (COP)'), findsOneWidget);
      expect(find.text(r'$120.000'), findsNWidgets(2));
    });
  });

  group('ManoMethodOption', () {
    testWidgets('a tap selects it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoMethodOption(
            leading: const Icon(Icons.phone_iphone),
            title: 'Nequi',
            detail: 'Apruebas el pago en tu celular',
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Nequi'));
      expect(taps, 1);
      expect(find.text('Apruebas el pago en tu celular'), findsOneWidget);
    });

    testWidgets('selected shows a checked radio', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoMethodOption(
            leading: const Icon(Icons.phone_iphone),
            title: 'Nequi',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('without onTap it is disabled and says why', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoMethodOption(
            leading: Icon(Icons.credit_card),
            title: 'Tarjeta',
            tag: 'Próximamente',
            selected: false,
            onTap: null,
          ),
        ),
      );

      expect(find.text('Próximamente'), findsOneWidget);
      await tester.tap(find.text('Tarjeta'));
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    });
  });

  group('ManoMethodRow', () {
    testWidgets('shows the method and fires its action', (tester) async {
      var edits = 0;
      await tester.pumpWidget(
        _host(
          ManoMethodRow(
            leading: const Icon(Icons.credit_card),
            title: 'Visa •••• 4242',
            detail: 'Vence 08/29',
            tag: 'Predeterminado',
            actionLabel: 'Editar',
            onAction: () => edits++,
          ),
        ),
      );

      expect(find.text('Visa •••• 4242'), findsOneWidget);
      expect(find.text('Vence 08/29'), findsOneWidget);
      expect(find.text('Predeterminado'), findsOneWidget);
      await tester.tap(find.text('Editar'));
      expect(edits, 1);
    });
  });

  group('ManoInfoCard', () {
    testWidgets('states the point and links to more', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          ManoInfoCard(
            icon: Icons.verified_user_outlined,
            title: 'Paga siempre a través de Mano',
            message: 'Así te protegemos.',
            linkLabel: 'Más información',
            onLink: () => opened++,
          ),
        ),
      );

      expect(find.text('Paga siempre a través de Mano'), findsOneWidget);
      expect(find.text('Así te protegemos.'), findsOneWidget);
      await tester.tap(find.text('Más información'));
      expect(opened, 1);
    });

    testWidgets('without a link it shows none', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoInfoCard(
            icon: Icons.info_outline,
            title: 'Título',
            message: 'Mensaje',
          ),
        ),
      );
      expect(find.byType(ManoTextAction), findsNothing);
    });
  });
}
