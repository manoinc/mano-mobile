import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import '../messaging/gateway_chat_json.dart';

const _ticketFields = 'mediaId uploadUrl headers { name value } expiresIn';

/// [MediaUploader] over mano-media: gateway ticket, PUT straight to storage, finalize.
final class GatewayMediaUploader implements MediaUploader {
  GatewayMediaUploader(
    this._transport, {
    http.Client? storage,
    this._unsupported,
  }) : _storage = storage ?? http.Client();

  final GatewayTransport _transport;
  final http.Client _storage;

  // Takes the targets the gateway has no upload kind for yet.
  final MediaUploader? _unsupported;

  static const _chatTicket =
      '''
mutation ChatTicket(\$chatId: ID!, \$contentType: String!) {
  requestChatMediaUpload(chatId: \$chatId, contentType: \$contentType) { $_ticketFields }
}''';

  static const _avatarTicket =
      '''
mutation AvatarTicket(\$contentType: String!) {
  requestAvatarUpload(contentType: \$contentType) { $_ticketFields }
}''';

  static const _finalize =
      '''
mutation Finalize(\$mediaId: ID!) {
  finalizeMediaUpload(mediaId: \$mediaId) { $mediaFields }
}''';

  @override
  Future<Result<MediaAttachment, DataFailure>> upload(
    PickedImage image,
    UploadTarget target,
  ) async {
    if (!image.isSupported) {
      return Err(
        DataRejected(reason: 'UnsupportedMimeType: ${image.mimeType}'),
      );
    }
    if (image.byteSize > target.maxBytes) {
      return const Err(DataRejected(reason: 'ObjectTooLarge'));
    }
    final request = _ticketFor(target, image.mimeType);
    if (request == null) {
      return _unsupported?.upload(image, target) ??
          const Err(DataUnavailable(detail: 'no gateway upload kind yet'));
    }
    final (document, field, variables) = request;
    return guardGateway(() async {
      final data = await _transport.run(document, variables: variables);
      final ticket = data[field] as Map<String, dynamic>;
      await _put(ticket, image);
      final done = await _transport.run(
        _finalize,
        variables: {'mediaId': ticket['mediaId']},
      );
      return toMediaAttachment(
        done['finalizeMediaUpload'] as Map<String, dynamic>,
      );
    });
  }

  // Null for targets the gateway has no upload kind for yet.
  static (String, String, Map<String, Object?>)? _ticketFor(
    UploadTarget target,
    String contentType,
  ) => switch (target) {
    ChatUpload(:final conversationId) => (
      _chatTicket,
      'requestChatMediaUpload',
      {'chatId': conversationId, 'contentType': contentType},
    ),
    AvatarUpload() => (
      _avatarTicket,
      'requestAvatarUpload',
      {'contentType': contentType},
    ),
    ProjectPhotoUpload() || PortfolioUpload() => null,
  };

  // The signature covers these headers, so they go out exactly as issued.
  Future<void> _put(Map<String, dynamic> ticket, PickedImage image) async {
    final headers = {
      for (final h in ticket['headers'] as List<dynamic>)
        (h as Map<String, dynamic>)['name'] as String: h['value'] as String,
    };
    final http.Response response;
    try {
      response = await _storage.put(
        Uri.parse(ticket['uploadUrl'] as String),
        headers: headers,
        body: image.bytes,
      );
    } on SocketException catch (e) {
      throw GatewayUnavailable('cannot reach media storage: $e');
    } on http.ClientException catch (e) {
      throw GatewayUnavailable('media upload failed: $e');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GatewayUnavailable('media storage answered ${response.statusCode}');
    }
  }
}
