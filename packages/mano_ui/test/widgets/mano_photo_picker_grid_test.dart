import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  45,
  180,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

ManoPickedPhoto _photo(String id, ManoPhotoStatus status) =>
    ManoPickedPhoto(id: id, image: MemoryImage(_png), status: status);

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  testWidgets('empty, it is just the add tile', (tester) async {
    var added = 0;
    await tester.pumpWidget(
      _host(ManoPhotoPickerGrid(photos: const [], onAdd: () => added++)),
    );

    await tester.tap(find.text('Agregar fotos'));
    expect(added, 1);
  });

  testWidgets('each photo can be removed; uploading shows progress', (
    tester,
  ) async {
    final removed = <String>[];
    await tester.pumpWidget(
      _host(
        ManoPhotoPickerGrid(
          photos: [
            _photo('a', ManoPhotoStatus.done),
            _photo('b', ManoPhotoStatus.uploading),
          ],
          onAdd: () {},
          onRemove: removed.add,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Quitar foto 1'));
    expect(removed, ['a']);
  });

  testWidgets('a failed photo offers a retry', (tester) async {
    final retried = <String>[];
    await tester.pumpWidget(
      _host(
        ManoPhotoPickerGrid(
          photos: [_photo('a', ManoPhotoStatus.failed)],
          onAdd: () {},
          onRetry: retried.add,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Reintentar foto 1'));
    expect(retried, ['a']);
  });

  testWidgets('the add tile disappears at the limit', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoPhotoPickerGrid(
          photos: [
            _photo('a', ManoPhotoStatus.done),
            _photo('b', ManoPhotoStatus.done),
          ],
          onAdd: () {},
          maxPhotos: 2,
        ),
      ),
    );

    expect(find.text('Agregar fotos'), findsNothing);
  });
}
