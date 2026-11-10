import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('ManoBarChart draws one bar and label per value', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoBarChart(
          labels: ['L', 'M', 'X'],
          values: [0, 50, 100],
          semanticLabel: 'Ganancias por día',
        ),
      ),
    );
    expect(find.byKey(const Key('mano-bar-0')), findsOneWidget);
    expect(find.byKey(const Key('mano-bar-2')), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    expect(find.bySemanticsLabel('Ganancias por día'), findsOneWidget);
  });

  testWidgets('ManoBarChart survives all-zero values', (tester) async {
    await tester.pumpWidget(
      _host(const ManoBarChart(labels: ['a', 'b'], values: [0, 0])),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ManoGreetingHeader shows an avatar only with a photo', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const ManoGreetingHeader(name: 'Ana')));
    expect(find.byType(ManoAvatar), findsNothing);
    await tester.pumpWidget(
      _host(const ManoGreetingHeader(name: 'Ana', photoUrl: null)),
    );
    expect(find.text('Hola, Ana'), findsOneWidget);
  });

  testWidgets('ManoStatTile shows value and label', (tester) async {
    await tester.pumpWidget(
      _host(const ManoStatTile(value: '4,9', label: 'Calificación')),
    );
    expect(find.text('4,9'), findsOneWidget);
    expect(find.text('Calificación'), findsOneWidget);
  });

  testWidgets('ManoReviewTile shows reviewer, date, text and stars', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ManoReviewTile(
          name: 'Laura',
          photoUrl: null,
          stars: 4,
          dateLabel: '12 oct',
          text: 'Excelente',
        ),
      ),
    );
    expect(find.text('Laura'), findsOneWidget);
    expect(find.text('12 oct'), findsOneWidget);
    expect(find.text('Excelente'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('ManoReferralCard calls back on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoReferralCard(
          title: 'Invita a un colega',
          subtitle: 'Gana 10 Mano coins por cada colega verificado',
          coinLabel: '10',
          detail: '2 colegas invitados · 1 verificado',
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('2 colegas invitados · 1 verificado'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.byType(ManoReferralCard));
    expect(taps, 1);
  });

  testWidgets('ManoReferralCard without a reward shows no coin or detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ManoReferralCard(
          title: 'Invita a un colega',
          subtitle: 'Comparte tu código RP-1a2b3c4d',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Comparte tu código RP-1a2b3c4d'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('10'), findsNothing);
  });
}
