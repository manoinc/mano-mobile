import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

final class _FakeChatRepository implements ChatRepository {
  final List<Message> history = [];
  Object? historyError;
  final incoming = StreamController<Message>.broadcast();
  final sent = <String>[];
  final markedRead = <String>[];
  Completer<Result<Message, DataFailure>>? pendingSend;

  @override
  Future<List<Message>> messages(String conversationId) async {
    final error = historyError;
    if (error != null) throw error;
    return List.of(history);
  }

  @override
  Stream<Message> watch(String conversationId) {
    return incoming.stream;
  }

  @override
  Future<Result<Message, DataFailure>> send(
    String conversationId,
    String body, {
    List<String> mediaIds = const [],
  }) {
    sent.add(body);
    pendingSend = Completer();
    return pendingSend!.future;
  }

  @override
  Future<Result<void, DataFailure>> markRead(String conversationId) async {
    markedRead.add(conversationId);
    return const Ok(null);
  }
}

final class _CountingConversations implements ConversationRepository {
  var calls = 0;

  @override
  Future<List<Conversation>> conversations() async {
    calls++;
    return const [];
  }

  @override
  Future<Result<Conversation, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  }) => throw UnimplementedError();
}

Message _message(
  String id,
  String body, {
  bool fromMe = false,
  MessageStatus status = MessageStatus.sent,
}) => Message(
  id: id,
  conversationId: 'c1',
  body: body,
  sentAt: DateTime(2026, 10, 1, 9),
  fromMe: fromMe,
  status: status,
);

ProviderContainer _container(
  ChatRepository chat, {
  ConversationRepository? conversations,
}) => ProviderContainer.test(
  overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
    conversationRepositoryProvider.overrideWithValue(
      conversations ?? _CountingConversations(),
    ),
  ],
);

List<String> _bodies(List<ChatThreadItem> items) => [
  for (final item in items) item.body,
];

Future<List<ChatThreadItem>> _load(ProviderContainer container) {
  container.listen(chatThreadProvider('c1'), (_, _) {});
  return container.read(chatThreadProvider('c1').future);
}

List<ChatThreadItem> _items(ProviderContainer container) =>
    container.read(chatThreadProvider('c1')).requireValue;

void main() {
  test('loads history as confirmed items, oldest first', () async {
    final repo = _FakeChatRepository()
      ..history.addAll([_message('m1', 'Hola'), _message('m2', 'Qué tal')]);
    final container = _container(repo);

    final items = await _load(container);

    expect(_bodies(items), ['Hola', 'Qué tal']);
    expect(items.every((item) => item is ConfirmedChatItem), isTrue);
  });

  test('a failed history load surfaces as an error', () async {
    final repo = _FakeChatRepository()..historyError = Exception('offline');
    final container = _container(repo);
    container.listen(chatThreadProvider('c1'), (_, _) {});

    await expectLater(
      container.read(chatThreadProvider('c1').future),
      throwsException,
    );
    expect(container.read(chatThreadProvider('c1')).hasError, isTrue);
  });

  test('marks the conversation read and refreshes the list on open', () async {
    final repo = _FakeChatRepository();
    final conversations = _CountingConversations();
    final container = _container(repo, conversations: conversations);
    container.listen(conversationsProvider, (_, _) {});
    await container.read(conversationsProvider.future);

    await _load(container);
    await pumpEventQueue();
    await container.read(conversationsProvider.future);

    expect(repo.markedRead, ['c1']);
    expect(conversations.calls, 2);
  });

  test('appends messages that arrive on the watch stream', () async {
    final repo = _FakeChatRepository();
    final container = _container(repo);
    await _load(container);

    repo.incoming.add(_message('m9', 'Ya llegué'));
    await pumpEventQueue();

    expect(_bodies(_items(container)), ['Ya llegué']);
  });

  test(
    'send shows a pending item, then swaps it for the confirmed one',
    () async {
      final repo = _FakeChatRepository();
      final container = _container(repo);
      await _load(container);

      final sending = container
          .read(chatThreadProvider('c1').notifier)
          .send(' Hola ');
      final pending = _items(container).single;
      expect(pending, isA<OutgoingChatItem>());
      expect((pending as OutgoingChatItem).failed, isFalse);
      expect(pending.body, 'Hola');

      repo.pendingSend!.complete(Ok(_message('m5', 'Hola', fromMe: true)));
      await sending;

      final confirmed = _items(container).single;
      expect(confirmed, isA<ConfirmedChatItem>());
      expect((confirmed as ConfirmedChatItem).message.id, 'm5');
    },
  );

  test(
    'a message both echoed on the stream and returned by send shows once',
    () async {
      final repo = _FakeChatRepository();
      final container = _container(repo);
      await _load(container);

      final sending = container
          .read(chatThreadProvider('c1').notifier)
          .send('Hola');
      final echoed = _message('m5', 'Hola', fromMe: true);
      repo.incoming.add(echoed);
      await pumpEventQueue();
      repo.pendingSend!.complete(Ok(echoed));
      await sending;

      expect(_bodies(_items(container)), ['Hola']);
      expect(_items(container).single, isA<ConfirmedChatItem>());
    },
  );

  test('a failed send stays visible as failed, and retry resends it', () async {
    final repo = _FakeChatRepository();
    final container = _container(repo);
    await _load(container);
    final notifier = container.read(chatThreadProvider('c1').notifier);

    final sending = notifier.send('Hola');
    repo.pendingSend!.complete(const Err(DataUnavailable()));
    await sending;

    final failed = _items(container).single as OutgoingChatItem;
    expect(failed.failed, isTrue);

    final retrying = notifier.retry(failed.localId);
    expect((_items(container).single as OutgoingChatItem).failed, isFalse);
    repo.pendingSend!.complete(Ok(_message('m6', 'Hola', fromMe: true)));
    await retrying;

    expect(repo.sent, ['Hola', 'Hola']);
    expect(_items(container).single, isA<ConfirmedChatItem>());
  });

  test('ignores blank sends', () async {
    final repo = _FakeChatRepository();
    final container = _container(repo);
    await _load(container);

    await container.read(chatThreadProvider('c1').notifier).send('   ');

    expect(repo.sent, isEmpty);
    expect(_items(container), isEmpty);
  });

  test('cancels the watch subscription on dispose', () async {
    final repo = _FakeChatRepository();
    final container = _container(repo);
    final sub = container.listen(chatThreadProvider('c1'), (_, _) {});
    await container.read(chatThreadProvider('c1').future);
    expect(repo.incoming.hasListener, isTrue);

    sub.close();
    await pumpEventQueue();

    expect(repo.incoming.hasListener, isFalse);
  });

  group('keeps the inbox fresh', () {
    Future<(ProviderContainer, _CountingConversations)> open(
      _FakeChatRepository repo,
    ) async {
      final conversations = _CountingConversations();
      final container = _container(repo, conversations: conversations);
      container.listen(conversationsProvider, (_, _) {});
      await container.read(conversationsProvider.future);
      await _load(container);
      await pumpEventQueue();
      await container.read(conversationsProvider.future);
      return (container, conversations);
    }

    test('an incoming message refetches the conversation list', () async {
      final repo = _FakeChatRepository();
      final (container, conversations) = await open(repo);
      final before = conversations.calls;

      repo.incoming.add(_message('m9', 'Ya llegué'));
      await pumpEventQueue();
      await container.read(conversationsProvider.future);

      expect(conversations.calls, before + 1);
    });

    test('a confirmed send refetches the conversation list', () async {
      final repo = _FakeChatRepository();
      final (container, conversations) = await open(repo);
      final before = conversations.calls;

      final sending = container
          .read(chatThreadProvider('c1').notifier)
          .send('Hola');
      repo.pendingSend!.complete(Ok(_message('m5', 'Hola', fromMe: true)));
      await sending;
      await container.read(conversationsProvider.future);

      expect(conversations.calls, before + 1);
    });
  });

  test(
    'a status update replaces the message and never downgrades it',
    () async {
      final repo = _FakeChatRepository();
      final container = _container(repo);
      await _load(container);

      repo.incoming.add(_message('m1', 'Hola', fromMe: true));
      repo.incoming.add(
        _message('m1', 'Hola', fromMe: true, status: MessageStatus.read),
      );
      repo.incoming.add(
        _message('m1', 'Hola', fromMe: true, status: MessageStatus.delivered),
      );
      await pumpEventQueue();

      final items = _items(container);
      expect(items, hasLength(1));
      expect(
        (items.single as ConfirmedChatItem).message.status,
        MessageStatus.read,
      );
    },
  );
}
