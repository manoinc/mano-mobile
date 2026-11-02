import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  XFile file(String name, {String? mimeType}) => XFile.fromData(
    Uint8List.fromList([9, 8, 7]),
    name: name,
    path: '/tmp/$name',
    mimeType: mimeType,
  );

  test('asks the plugin for the matching source, shrunk for upload', () async {
    final asked = <(ImageSource, double?, int?)>[];
    final picker = ImagePickerMediaPicker(
      pick: (source, {maxWidth, imageQuality}) async {
        asked.add((source, maxWidth, imageQuality));
        return file('a.jpg');
      },
    );

    await picker.pick(PhotoSource.camera);
    await picker.pick(PhotoSource.gallery);

    expect(asked, [
      (ImageSource.camera, 1600.0, 80),
      (ImageSource.gallery, 1600.0, 80),
    ]);
  });

  test('reads the bytes and names the type from the extension', () async {
    for (final (name, mime) in [
      ('a.JPG', 'image/jpeg'),
      ('a.jpeg', 'image/jpeg'),
      ('b.png', 'image/png'),
      ('c.webp', 'image/webp'),
      ('d.heic', 'image/heic'),
    ]) {
      final picker = ImagePickerMediaPicker(
        pick: (_, {maxWidth, imageQuality}) async => file(name),
      );
      final image = (await picker.pick(PhotoSource.gallery))!;
      expect(image.mimeType, mime, reason: name);
      expect(image.bytes, [9, 8, 7]);
      expect(image.name, name);
    }
  });

  test('prefers the type the plugin reports', () async {
    final picker = ImagePickerMediaPicker(
      pick: (_, {maxWidth, imageQuality}) async =>
          file('x', mimeType: 'image/png'),
    );
    expect((await picker.pick(PhotoSource.gallery))!.mimeType, 'image/png');
  });

  test('backing out is null', () async {
    final picker = ImagePickerMediaPicker(
      pick: (_, {maxWidth, imageQuality}) async => null,
    );
    expect(await picker.pick(PhotoSource.gallery), isNull);
  });
}
