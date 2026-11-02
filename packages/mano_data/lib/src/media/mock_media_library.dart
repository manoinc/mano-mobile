import 'package:mano_domain/mano_domain.dart';

/// Offline stand-in for the media store, shared by the mock uploader and chat.
final class MockMediaLibrary {
  final Map<String, MediaAttachment> _byId = {};

  void add(MediaAttachment attachment) => _byId[attachment.id] = attachment;

  MediaAttachment? operator [](String id) => _byId[id];
}
