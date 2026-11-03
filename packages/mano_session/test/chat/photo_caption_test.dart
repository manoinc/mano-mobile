import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('a photo with no text goes out with the default caption', () {
    expect(outgoingBody('', hasPhotos: true), photoOnlyCaption);
    expect(photoOnlyCaption, '📷 Foto');
  });

  test('typed text goes out as typed, with or without photos', () {
    expect(outgoingBody('Mira', hasPhotos: true), 'Mira');
    expect(outgoingBody('Hola', hasPhotos: false), 'Hola');
  });

  test('the default caption is hidden under photos only', () {
    expect(visibleCaption(photoOnlyCaption, hasPhotos: true), '');
    expect(
      visibleCaption(photoOnlyCaption, hasPhotos: false),
      photoOnlyCaption,
    );
    expect(visibleCaption('Mira', hasPhotos: true), 'Mira');
  });
}
