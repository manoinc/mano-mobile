import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('offers the gallery and the camera', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: ManoMediaSourceSheet(
            onGallery: () => picked.add('gallery'),
            onCamera: () => picked.add('camera'),
          ),
        ),
      ),
    );

    expect(find.text('Agregar foto'), findsOneWidget);
    await tester.tap(find.text('Elegir de la galería'));
    await tester.tap(find.text('Tomar foto'));
    expect(picked, ['gallery', 'camera']);
  });
}
