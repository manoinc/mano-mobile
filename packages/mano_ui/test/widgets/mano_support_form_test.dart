import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  late TextEditingController subject;
  late TextEditingController description;

  setUp(() {
    subject = TextEditingController();
    description = TextEditingController();
  });

  Future<List<int>> pump(
    WidgetTester tester, {
    String? subjectError,
    List<String>? changes,
  }) async {
    final picked = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ManoSupportForm(
              kinds: const ['Petición', 'Queja', 'Reclamo', 'Sugerencia'],
              selectedKind: 1,
              onKind: picked.add,
              subject: subject,
              description: description,
              onChanged: () => changes?.add(subject.text),
              subjectError: subjectError,
            ),
          ),
        ),
      ),
    );
    return picked;
  }

  testWidgets('picks a kind', (tester) async {
    final picked = await pump(tester);
    expect(find.text('Queja'), findsOneWidget);
    await tester.tap(find.text('Reclamo'));
    expect(picked, [2]);
  });

  testWidgets('reports typing and shows errors', (tester) async {
    final changes = <String>[];
    await pump(tester, subjectError: 'Escribe un asunto', changes: changes);

    await tester.enterText(find.byKey(const Key('support-subject')), 'Pago');
    await tester.enterText(
      find.byKey(const Key('support-description')),
      'Detalle',
    );

    expect(changes, ['Pago', 'Pago']);
    expect(description.text, 'Detalle');
    expect(find.text('Escribe un asunto'), findsOneWidget);
  });

  testWidgets('fits a 360 dp phone at twice the text size', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ManoSupportForm(
                kinds: const ['Petición', 'Queja', 'Reclamo', 'Sugerencia'],
                selectedKind: 0,
                onKind: (_) {},
                subject: subject,
                description: description,
                onChanged: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
