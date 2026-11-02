import 'dart:async';

import 'package:mano_domain/mano_domain.dart';

import '../media/mock_media_library.dart';

import 'mock_conversation_repository.dart';

/// In-memory [ChatRepository]; the other side optionally replies after [replyDelay].
final class MockChatRepository implements ChatRepository {
  MockChatRepository({
    DateTime Function()? now,
    this.replyDelay,
    this._conversations,
    MockMediaLibrary? media,
  }) : _now = now ?? DateTime.now,
       _media = media ?? MockMediaLibrary() {
    final t = _now();
    _threads['conv-1'] = [
      _msg(
        'conv-1',
        'Hola, ¿tienes disponibilidad el jueves?',
        t.subtract(const Duration(hours: 3)),
        fromMe: true,
      ),
      _msg(
        'conv-1',
        '¡Hola! Sí, en la mañana.',
        t.subtract(const Duration(hours: 2, minutes: 50)),
        fromMe: false,
      ),
      _msg(
        'conv-1',
        '¿Aún disponible para el jueves?',
        t.subtract(const Duration(hours: 1)),
        fromMe: false,
      ),
    ];
    _threads['conv-2'] = [
      _msg(
        'conv-2',
        'Gracias por el trabajo de ayer.',
        t.subtract(const Duration(days: 1)),
        fromMe: true,
      ),
      _msg(
        'conv-2',
        'Perfecto, te veo mañana.',
        t.subtract(const Duration(hours: 20)),
        fromMe: false,
      ),
    ];
  }

  final Duration? replyDelay;
  final MockConversationRepository? _conversations;
  final DateTime Function() _now;
  final MockMediaLibrary _media;
  final Map<String, List<Message>> _threads = {};
  final Map<String, StreamController<Message>> _streams = {};
  int _nextId = 100;

  Message _msg(
    String conversationId,
    String body,
    DateTime at, {
    required bool fromMe,
    List<MediaAttachment> media = const [],
  }) => Message(
    id: 'msg-${_nextId++}',
    conversationId: conversationId,
    body: body,
    sentAt: at,
    fromMe: fromMe,
    media: media,
  );

  StreamController<Message> _stream(String id) =>
      _streams.putIfAbsent(id, StreamController<Message>.broadcast);

  void _deliver(Message message) {
    _threads.putIfAbsent(message.conversationId, () => []).add(message);
    _stream(message.conversationId).add(message);
    _conversations?.recordMessage(
      message.conversationId,
      message.body,
      message.sentAt,
    );
  }

  void _setStatus(Message message, MessageStatus status) {
    final thread = _threads[message.conversationId]!;
    final index = thread.indexWhere((m) => m.id == message.id);
    if (index < 0) return;
    thread[index] = thread[index].copyWith(status: status);
    _stream(message.conversationId).add(thread[index]);
  }

  void _markMineRead(String conversationId) {
    final thread = _threads[conversationId] ?? const <Message>[];
    for (final m in List.of(thread)) {
      if (m.fromMe && m.status != MessageStatus.read) {
        _setStatus(m, MessageStatus.read);
      }
    }
  }

  @override
  Future<List<Message>> messages(String conversationId) async =>
      List.of(_threads[conversationId] ?? const []);

  @override
  Stream<Message> watch(String conversationId) =>
      _stream(conversationId).stream;

  @override
  Future<Result<Message, DataFailure>> send(
    String conversationId,
    String body, {
    List<String> mediaIds = const [],
  }) async {
    final media = [for (final id in mediaIds) _media[id]];
    if (media.contains(null)) {
      return const Err(DataRejected(reason: 'unknown media'));
    }
    // chatservice refuses empty content even with photos attached.
    if (body.trim().isEmpty) {
      return const Err(DataRejected(reason: 'empty message'));
    }
    final sent = _msg(
      conversationId,
      body.trim(),
      _now(),
      fromMe: true,
      media: media.cast<MediaAttachment>(),
    );
    _deliver(sent);
    // Delivered a tick later, so listeners see sent first.
    Future.microtask(() => _setStatus(sent, MessageStatus.delivered));
    final delay = replyDelay;
    if (delay != null) {
      Timer(delay, () {
        _deliver(
          _msg(
            conversationId,
            '¡Recibido! Te respondo en un momento.',
            _now(),
            fromMe: false,
          ),
        );
        _markMineRead(conversationId);
      });
    }
    return Ok(sent);
  }

  @override
  Future<Result<void, DataFailure>> markRead(String conversationId) async {
    _conversations?.markRead(conversationId);
    return const Ok(null);
  }
}
