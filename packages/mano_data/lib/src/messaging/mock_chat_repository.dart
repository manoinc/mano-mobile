import 'dart:async';

import 'package:mano_domain/mano_domain.dart';

import 'mock_conversation_repository.dart';

/// In-memory [ChatRepository]; the other side optionally replies after [replyDelay].
final class MockChatRepository implements ChatRepository {
  MockChatRepository({
    DateTime Function()? now,
    this.replyDelay,
    this._conversations,
  }) : _now = now ?? DateTime.now {
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
  final Map<String, List<Message>> _threads = {};
  final Map<String, StreamController<Message>> _streams = {};
  int _nextId = 100;

  Message _msg(
    String conversationId,
    String body,
    DateTime at, {
    required bool fromMe,
  }) => Message(
    id: 'msg-${_nextId++}',
    conversationId: conversationId,
    body: body,
    sentAt: at,
    fromMe: fromMe,
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

  @override
  Future<List<Message>> messages(String conversationId) async =>
      List.of(_threads[conversationId] ?? const []);

  @override
  Stream<Message> watch(String conversationId) =>
      _stream(conversationId).stream;

  @override
  Future<Result<Message, DataFailure>> send(
    String conversationId,
    String body,
  ) async {
    if (body.trim().isEmpty) {
      return const Err(DataRejected(reason: 'empty message'));
    }
    final sent = _msg(conversationId, body.trim(), _now(), fromMe: true);
    _deliver(sent);
    final delay = replyDelay;
    if (delay != null) {
      Timer(
        delay,
        () => _deliver(
          _msg(
            conversationId,
            '¡Recibido! Te respondo en un momento.',
            _now(),
            fromMe: false,
          ),
        ),
      );
    }
    return Ok(sent);
  }

  @override
  Future<Result<void, DataFailure>> markRead(String conversationId) async {
    _conversations?.markRead(conversationId);
    return const Ok(null);
  }
}
