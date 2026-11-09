import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

final _photo = PickedImage(
  bytes: Uint8List(4),
  mimeType: 'image/jpeg',
  name: 'id.jpg',
);

void main() {
  test('starts with nothing sent', () async {
    final port = MockIdentityVerification();

    final status = (await port.status()).valueOrNull;

    expect(status, isA<IdentityCheckInProgress>());
    expect((status! as IdentityCheckInProgress).submitted, isEmpty);
  });

  test('refuses to finish while a document is missing', () async {
    final port = MockIdentityVerification();
    await port.submit(IdentityDocumentKind.cedulaFront, _photo);

    expect((await port.finish()).failureOrNull, isA<DataRejected>());
  });

  test('all three documents go to review', () async {
    final port = MockIdentityVerification();
    for (final kind in IdentityDocumentKind.values) {
      await port.submit(kind, _photo);
    }

    expect((await port.finish()).valueOrNull, isA<IdentityCheckPending>());
    expect((await port.status()).valueOrNull, isA<IdentityCheckPending>());
  });
}
