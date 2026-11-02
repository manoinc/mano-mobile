import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

const _putUrl =
    'http://127.0.0.1:3900/mano-media/chat/c1/md1.jpg?X-Amz-Signature=abc';

final _photo = PickedImage(
  bytes: Uint8List.fromList([1, 2, 3]),
  mimeType: 'image/jpeg',
  name: 'foto.jpg',
);

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

Map<String, Object?> _ticket() => {
  'mediaId': 'md1',
  'uploadUrl': _putUrl,
  'headers': [
    {'name': 'Content-Type', 'value': 'image/jpeg'},
  ],
  'expiresIn': 900,
};

Map<String, Object?> _media() => {
  'mediaId': 'md1',
  'mimeType': 'image/jpeg',
  'byteSize': 3,
  'url': 'http://127.0.0.1:3900/mano-media/chat/c1/md1.jpg?X-Amz=get',
};

/// Records each call and answers the ticket, the PUT and the finalize.
final class _Backend {
  _Backend({this.putStatus = 200, this.finalize});

  final int putStatus;
  final http.Response Function()? finalize;
  final calls = <http.Request>[];

  Future<http.Response> handle(http.Request r) async {
    calls.add(r);
    if (r.method == 'PUT') return http.Response('', putStatus);
    final query = (jsonDecode(r.body) as Map)['query'] as String;
    if (query.contains('finalizeMediaUpload')) {
      return finalize?.call() ?? _data({'finalizeMediaUpload': _media()});
    }
    if (query.contains('requestChatMediaUpload')) {
      return _data({'requestChatMediaUpload': _ticket()});
    }
    if (query.contains('requestAvatarUpload')) {
      return _data({'requestAvatarUpload': _ticket()});
    }
    throw StateError('unexpected $query');
  }
}

GatewayMediaUploader _uploader(_Backend backend, {MediaUploader? fallback}) {
  final client = MockClient(backend.handle);
  return GatewayMediaUploader(
    GatewayTransport(_config, httpClient: client),
    storage: client,
    unsupported: fallback,
  );
}

Map<String, dynamic> _graphql(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

void main() {
  test('a chat photo: ticket, PUT with the signed headers, finalize', () async {
    final backend = _Backend();

    final result = await _uploader(backend)
        .upload(_photo, const ChatUpload('c1'));

    expect(
      result.valueOrNull,
      const MediaAttachment(
        id: 'md1',
        url: 'http://127.0.0.1:3900/mano-media/chat/c1/md1.jpg?X-Amz=get',
        mimeType: 'image/jpeg',
        byteSize: 3,
      ),
    );
    final [ticket, put, finalize] = backend.calls;
    expect(_graphql(ticket)['variables'], {
      'chatId': 'c1',
      'contentType': 'image/jpeg',
    });
    expect(put.method, 'PUT');
    expect(put.url.toString(), _putUrl);
    expect(put.headers['Content-Type'], startsWith('image/jpeg'));
    expect(put.bodyBytes, [1, 2, 3]);
    expect(_graphql(finalize)['variables'], {'mediaId': 'md1'});
  });

  test('an avatar asks for an avatar ticket', () async {
    final backend = _Backend();

    await _uploader(backend).upload(_photo, const AvatarUpload());

    final query = _graphql(backend.calls.first)['query'] as String;
    expect(query, contains('requestAvatarUpload(contentType: \$contentType)'));
    expect(_graphql(backend.calls.first)['variables'], {
      'contentType': 'image/jpeg',
    });
  });

  test('a failed PUT is unavailable and nothing is finalized', () async {
    final backend = _Backend(putStatus: 403);

    final result = await _uploader(backend)
        .upload(_photo, const ChatUpload('c1'));

    expect(result.failureOrNull, isA<DataUnavailable>());
    expect(backend.calls, hasLength(2));
  });

  test('a refused finalize (too large) is a rejection', () async {
    final backend = _Backend(
      finalize: () => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'ObjectTooLarge: 120000000 bytes'},
          ],
        }),
        200,
      ),
    );

    final result = await _uploader(backend)
        .upload(_photo, const ChatUpload('c1'));

    expect(result.failureOrNull, isA<DataRejected>());
  });

  test(
    'an unsupported type or oversized file never leaves the phone',
    () async {
      final backend = _Backend();
      final uploader = _uploader(backend);

      final heic = PickedImage(
        bytes: Uint8List(1),
        mimeType: 'image/heic',
        name: 'a.heic',
      );
      final huge = PickedImage(
        bytes: Uint8List(2 * 1024 * 1024 + 1),
        mimeType: 'image/png',
        name: 'a.png',
      );

      expect(
        (await uploader.upload(heic, const ChatUpload('c1'))).failureOrNull,
        isA<DataRejected>(),
      );
      expect(
        (await uploader.upload(huge, const AvatarUpload())).failureOrNull,
        isA<DataRejected>(),
      );
      expect(backend.calls, isEmpty);
    },
  );

  test('targets the gateway cannot store yet go to the fallback', () async {
    final backend = _Backend();
    final fallback = MockMediaUploader(delay: Duration.zero);

    final result = await _uploader(
      backend,
      fallback: fallback,
    ).upload(_photo, const ProjectPhotoUpload());

    expect(result.isOk, isTrue);
    expect(backend.calls, isEmpty);
  });

  test('without a fallback those targets are unavailable', () async {
    final result = await _uploader(_Backend())
        .upload(_photo, const PortfolioUpload());

    expect(result.failureOrNull, isA<DataUnavailable>());
  });
}
