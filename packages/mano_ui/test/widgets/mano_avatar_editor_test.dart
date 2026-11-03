import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  testWidgets('falls back to the person icon with no photo', (tester) async {
    await tester.pumpWidget(
      _host(ManoAvatarEditor(photoUrl: null, onTap: () {})),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'a local image wins over the url, with a spinner while uploading',
    (tester) async {
      await tester.pumpWidget(
        _host(
          ManoAvatarEditor(
            photoUrl: 'https://example.com/old.png',
            localImage: MemoryImage(_png),
            uploading: true,
            onTap: () {},
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('tapping reports, and is labelled for screen readers', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(ManoAvatarEditor(photoUrl: null, onTap: () => taps++)),
    );

    await tester.tap(find.bySemanticsLabel('Cambiar foto'));
    expect(taps, 1);
  });

  testWidgets('ignores taps while uploading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoAvatarEditor(photoUrl: null, uploading: true, onTap: () => taps++),
      ),
    );

    await tester.tap(find.byType(ManoAvatarEditor));
    expect(taps, 0);
  });
}
