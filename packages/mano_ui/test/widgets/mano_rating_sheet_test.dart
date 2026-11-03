import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

ManoRatingSheet _sheet({
  int stars = 0,
  ValueChanged<int>? onStars,
  ValueChanged<String>? onComment,
  VoidCallback? onSubmit,
  VoidCallback? onClose,
  VoidCallback? onDone,
  bool busy = false,
  String? error,
  bool done = false,
}) => ManoRatingSheet(
  title: '¿Cómo te fue con Carlos?',
  subtitle: 'Tu calificación ayuda a otros.',
  stars: stars,
  onStarsChanged: onStars ?? (_) {},
  onCommentChanged: onComment ?? (_) {},
  onSubmit: onSubmit,
  onClose: onClose ?? () {},
  busy: busy,
  error: error,
  done: done,
  doneTitle: '¡Gracias!',
  doneMessage: 'Guardamos tu calificación.',
  onDone: onDone ?? () {},
);

void main() {
  testWidgets('shows the title, the subtitle and five stars', (tester) async {
    await tester.pumpWidget(_host(_sheet()));

    expect(find.text('¿Cómo te fue con Carlos?'), findsOneWidget);
    expect(find.text('Tu calificación ayuda a otros.'), findsOneWidget);
    expect(find.byType(ManoStarInput), findsOneWidget);
  });

  testWidgets('the comment waits until a star is chosen', (tester) async {
    await tester.pumpWidget(_host(_sheet()));
    expect(find.byType(TextField), findsNothing);

    await tester.pumpWidget(_host(_sheet(stars: 4)));
    await tester.pumpAndSettle();
    expect(find.text('Comentario (opcional)'), findsOneWidget);
  });

  testWidgets('reports stars, comment and send', (tester) async {
    int? stars;
    String? comment;
    var sent = false;
    await tester.pumpWidget(
      _host(
        _sheet(
          stars: 3,
          onStars: (v) => stars = v,
          onComment: (v) => comment = v,
          onSubmit: () => sent = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.enterText(find.byType(TextField), 'Puntual');
    await tester.tap(find.text('Enviar'));

    expect(stars, 5);
    expect(comment, 'Puntual');
    expect(sent, isTrue);
  });

  testWidgets('send is disabled without a callback', (tester) async {
    await tester.pumpWidget(_host(_sheet()));

    final button = tester.widget<ManoPrimaryButton>(
      find.byType(ManoPrimaryButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a refusal above the action', (tester) async {
    await tester.pumpWidget(
      _host(_sheet(stars: 3, error: 'Aún no puedes calificar este trabajo.')),
    );

    expect(find.text('Aún no puedes calificar este trabajo.'), findsOneWidget);
  });

  testWidgets('the close control calls back', (tester) async {
    var closed = false;
    await tester.pumpWidget(_host(_sheet(onClose: () => closed = true)));

    await tester.tap(find.byTooltip('Cerrar'));

    expect(closed, isTrue);
  });

  testWidgets('done thanks the person and offers Listo', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      _host(_sheet(stars: 5, done: true, onDone: () => finished = true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Gracias!'), findsOneWidget);
    expect(find.text('Guardamos tu calificación.'), findsOneWidget);
    expect(find.byType(ManoStarInput), findsNothing);

    await tester.tap(find.text('Listo'));
    expect(finished, isTrue);
  });
}
