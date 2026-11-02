import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _container({required bool offline}) => ProviderContainer.test(
  overrides: [
    manoConfigProvider.overrideWithValue(
      const ManoConfig(
        gatewayGraphQlUrl: 'http://gw/graphql',
        appRole: ManoRole.requester,
      ),
    ),
    offlineMarketplaceProvider.overrideWithValue(offline),
  ],
);

void main() {
  test('live uploads go through the gateway', () {
    expect(
      _container(offline: false).read(mediaUploaderProvider),
      isA<GatewayMediaUploader>(),
    );
  });

  test('offline uploads stay in memory', () {
    expect(
      _container(offline: true).read(mediaUploaderProvider),
      isA<MockMediaUploader>(),
    );
  });

  test('the picker is the device one', () {
    expect(
      _container(offline: true).read(mediaPickerProvider),
      isA<ImagePickerMediaPicker>(),
    );
  });

  test('offline, a photo uploaded to a chat can be sent in it', () async {
    final container = _container(offline: true);
    final uploaded =
        (await container
                .read(mediaUploaderProvider)
                .upload(
                  PickedImage(
                    bytes: Uint8List(4),
                    mimeType: 'image/png',
                    name: 'a.png',
                  ),
                  const ChatUpload('conv-1'),
                ))
            .valueOrNull!;

    final sent = await container
        .read(chatRepositoryProvider)
        .send('conv-1', 'Así quedó', mediaIds: [uploaded.id]);

    expect(sent.valueOrNull!.media, [uploaded]);
  });
}
