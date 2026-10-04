import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

ManoRequestCard _card({
  VoidCallback? onTap,
  String? statusLabel,
  Widget? actions,
}) => ManoRequestCard(
  clientName: 'Laura Pérez',
  clientPhotoUrl: 'https://example.com/laura.jpg',
  title: 'Limpieza profunda',
  message: 'Tengo una fuga debajo del lavaplatos.',
  scheduleLabel: 'sáb 10 oct, 9:00 a. m.',
  amountLabel: r'$120.000',
  rateLabel: 'precio fijo',
  statusLabel: statusLabel,
  statusTone: ManoStatusTone.success,
  onTap: onTap ?? () {},
  actions: actions,
);

void main() {
  group('the request card', () {
    testWidgets('renders client, service, message, schedule and price', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_card()));

      expect(find.text('Laura Pérez'), findsOneWidget);
      expect(find.text('Limpieza profunda'), findsOneWidget);
      expect(
        find.text('Tengo una fuga debajo del lavaplatos.'),
        findsOneWidget,
      );
      expect(find.text('sáb 10 oct, 9:00 a. m.'), findsOneWidget);
      expect(find.text(r'$120.000'), findsOneWidget);
      expect(find.byType(ManoAvatar), findsOneWidget);
    });

    testWidgets('clamps the message to two lines', (tester) async {
      await tester.pumpWidget(_host(_card()));
      final message = tester.widget<Text>(
        find.text('Tengo una fuga debajo del lavaplatos.'),
      );
      expect(message.maxLines, 2);
      expect(message.overflow, TextOverflow.ellipsis);
    });

    testWidgets('shows a status chip only when given a label', (tester) async {
      await tester.pumpWidget(_host(_card()));
      expect(find.byType(ManoStatusChip), findsNothing);

      await tester.pumpWidget(_host(_card(statusLabel: 'Aceptada')));
      expect(find.byType(ManoStatusChip), findsOneWidget);
      expect(find.text('Aceptada'), findsOneWidget);
    });

    testWidgets('renders the actions slot', (tester) async {
      await tester.pumpWidget(
        _host(_card(actions: const Text('Aceptar', key: Key('slot')))),
      );
      expect(find.byKey(const Key('slot')), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(_card(onTap: () => taps++)));
      await tester.tap(find.text('Limpieza profunda'));
      expect(taps, 1);
    });
  });
}
