import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/tiny_png.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

final _attach = find.byKey(const Key('mano-composer-attach'));
final _send = find.byKey(const Key('mano-composer-send'));

void main() {
  testWidgets('no attach button without onAttach', (tester) async {
    await tester.pumpWidget(
      _host(ManoMessageComposer(hintText: 'Escribe', onSend: (_) {})),
    );
    expect(_attach, findsNothing);
  });

  testWidgets('the attach button calls onAttach and is labelled', (
    tester,
  ) async {
    var attached = 0;
    await tester.pumpWidget(
      _host(
        ManoMessageComposer(
          hintText: 'Escribe',
          onSend: (_) {},
          onAttach: () => attached++,
        ),
      ),
    );

    expect(find.byTooltip('Agregar foto'), findsOneWidget);
    await tester.tap(_attach);
    expect(attached, 1);
  });

  testWidgets('pending photos show as thumbnails that can be removed', (
    tester,
  ) async {
    final removed = <String>[];
    await tester.pumpWidget(
      _host(
        ManoMessageComposer(
          hintText: 'Escribe',
          onSend: (_) {},
          onAttach: () {},
          attachments: [
            ManoPickedPhoto(id: 'a', image: tinyImage),
            ManoPickedPhoto(
              id: 'b',
              image: tinyImage,
              status: ManoPhotoStatus.uploading,
            ),
          ],
          onRemoveAttachment: removed.add,
        ),
      ),
    );

    expect(find.byKey(const Key('mano-composer-attachments')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Quitar foto 2'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    expect(removed, ['b']);
  });

  testWidgets('with photos attached, an empty draft can be sent', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      _host(
        ManoMessageComposer(
          hintText: 'Escribe',
          onSend: sent.add,
          attachments: [ManoPickedPhoto(id: 'a', image: tinyImage)],
        ),
      ),
    );

    await tester.tap(_send);
    expect(sent, ['']);
  });

  testWidgets('canSend false disables sending', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      _host(
        ManoMessageComposer(
          hintText: 'Escribe',
          onSend: sent.add,
          canSend: false,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hola');
    await tester.tap(_send);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    expect(sent, isEmpty);
    expect(tester.widget<IconButton>(_send).onPressed, isNull);
  });
}
