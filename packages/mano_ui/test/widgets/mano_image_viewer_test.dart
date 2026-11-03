import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/tiny_png.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ManoTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ManoImageViewer.show(context, image: tinyImage),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on black with a zoomable photo', (tester) async {
    await _open(tester);

    expect(find.byType(ManoImageViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final ground = tester.widget<ColoredBox>(
      find.byKey(const Key('mano-image-viewer-ground')),
    );
    expect(ground.color, Colors.black);
  });

  testWidgets('the close button closes it', (tester) async {
    await _open(tester);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(ManoImageViewer), findsNothing);
  });

  testWidgets('a tap on the photo closes it', (tester) async {
    await _open(tester);

    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();

    expect(find.byType(ManoImageViewer), findsNothing);
  });

  testWidgets('a swipe down closes it, a nudge does not', (tester) async {
    await _open(tester);

    await tester.drag(find.byType(InteractiveViewer), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(find.byType(ManoImageViewer), findsOneWidget);

    await tester.fling(
      find.byType(InteractiveViewer),
      const Offset(0, 300),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ManoImageViewer), findsNothing);
  });
}
