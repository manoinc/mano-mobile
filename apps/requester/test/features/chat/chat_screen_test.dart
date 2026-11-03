import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_media_picker.dart';
import '../../support/pump_app.dart';

final class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({this.history = const [], this.failLoads = 0});

  final List<Message> history;
  int failLoads;
  final incoming = StreamController<Message>.broadcast();
  final sends = <Completer<Result<Message, DataFailure>>>[];
  final bodies = <String>[];
  final mediaIds = <List<String>>[];

  @override
  Future<List<Message>> messages(String conversationId) async {
    if (failLoads > 0) {
      failLoads--;
      throw Exception('offline');
    }
    return history;
  }

  @override
  Stream<Message> watch(String conversationId) => incoming.stream;

  @override
  Future<Result<Message, DataFailure>> send(
    String conversationId,
    String body, {
    List<String> mediaIds = const [],
  }) {
    bodies.add(body);
    this.mediaIds.add(mediaIds);
    final completer = Completer<Result<Message, DataFailure>>();
    sends.add(completer);
    return completer.future;
  }

  @override
  Future<Result<void, DataFailure>> markRead(String conversationId) async =>
      const Ok(null);
}

final class _OneConversation implements ConversationRepository {
  _OneConversation(this.conversation);

  final Conversation conversation;

  @override
  Future<List<Conversation>> conversations() async => [conversation];

  @override
  Future<Result<Conversation, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  }) => throw UnimplementedError();
}

Message _message(String id, String body, DateTime at, {bool fromMe = false}) =>
    Message(
      id: id,
      conversationId: 'conv-1',
      body: body,
      sentAt: at,
      fromMe: fromMe,
    );

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byKey(const Key('mano-composer-send')));
  await tester.pump();
}

void main() {
  testWidgets('the header shows the participant and their verified badge', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/inbox/conv-1');

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Ana Gómez'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.verified),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unnamed professional is called Profesional in the header', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/inbox/conv-9',
      overrides: [
        conversationRepositoryProvider.overrideWithValue(
          _OneConversation(
            const Conversation(
              id: 'conv-9',
              participant: Party(id: 'w9', displayName: '', photoUrl: ''),
              participantRole: ManoRole.provider,
            ),
          ),
        ),
      ],
    );

    expect(
      find.descendant(
        of: find.byType(ManoChatHeader),
        matching: find.text('Profesional'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the header opens the participant profile', (
    tester,
  ) async {
    final container = await pumpRouterAt(tester, '/inbox/conv-1');

    await tester.tap(find.byType(ManoChatHeader));
    await tester.pumpAndSettle();

    final sheet = find.byType(ManoProfileSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Ana Gómez')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Profesional')),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver perfil'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoProfileSheet), findsNothing);
    expect(routerPath(container), '/provider/provider-2');
  });

  testWidgets('a client in the header has no profile to open', (tester) async {
    await pumpRouterAt(
      tester,
      '/inbox/conv-9',
      overrides: [
        conversationRepositoryProvider.overrideWithValue(
          _OneConversation(
            const Conversation(
              id: 'conv-9',
              participant: Party(id: 'c9', displayName: 'Luz', photoUrl: ''),
              participantRole: ManoRole.requester,
            ),
          ),
        ),
      ],
    );

    await tester.tap(find.byType(ManoChatHeader));
    await tester.pumpAndSettle();

    expect(find.text('Ver perfil'), findsNothing);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoProfileSheet), findsNothing);
  });

  testWidgets('my last message shows its read receipt', (tester) async {
    final repo = _FakeChatRepository(
      history: [
        Message(
          id: 'm1',
          conversationId: 'conv-1',
          body: 'Hola',
          sentAt: DateTime(2026, 10, 1, 9),
          fromMe: true,
          status: MessageStatus.read,
        ),
      ],
    );
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );

    expect(find.byKey(const Key('chat-receipt-read')), findsOneWidget);
  });

  testWidgets('renders the history as bubbles with day separators', (
    tester,
  ) async {
    final repo = _FakeChatRepository(
      history: [
        _message('m1', 'Hola', DateTime(2026, 10, 1, 9), fromMe: true),
        _message('m2', 'Buenos días', DateTime(2026, 10, 2, 8)),
      ],
    );
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );

    expect(find.byType(ManoChatBubble), findsNWidgets(2));
    expect(find.text('1 oct'), findsOneWidget);
    expect(find.text('2 oct'), findsOneWidget);
    expect(find.text('9:00 a. m.'), findsOneWidget);
    final mine = tester.widget<ManoChatBubble>(
      find.widgetWithText(ManoChatBubble, 'Hola'),
    );
    expect(mine.mine, isTrue);
  });

  testWidgets('an empty thread invites the first message', (tester) async {
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [
        chatRepositoryProvider.overrideWithValue(_FakeChatRepository()),
      ],
    );

    expect(find.text('Escribe el primer mensaje'), findsOneWidget);
    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });

  testWidgets('a failed load shows an error with retry', (tester) async {
    final repo = _FakeChatRepository(
      history: [_message('m1', 'Hola', DateTime(2026, 10, 1, 9))],
      failLoads: 1,
    );
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );

    expect(find.text('No se pudo cargar la conversación.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ManoChatBubble, 'Hola'), findsOneWidget);
  });

  testWidgets('a sent message shows pending, then confirmed', (tester) async {
    final repo = _FakeChatRepository();
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );

    await _type(tester, 'Hola');
    expect(find.byKey(const Key('chat-item-pending')), findsOneWidget);
    expect(find.text('Enviando…'), findsOneWidget);

    repo.sends.single.complete(
      Ok(_message('m5', 'Hola', DateTime(2026, 10, 1, 9), fromMe: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-item-pending')), findsNothing);
    expect(find.widgetWithText(ManoChatBubble, 'Hola'), findsOneWidget);
    expect(find.text('9:00 a. m.'), findsOneWidget);
  });

  testWidgets('a failed send stays visible and retries on tap', (tester) async {
    final repo = _FakeChatRepository();
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );

    await _type(tester, 'Hola');
    repo.sends.single.complete(const Err(DataUnavailable()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-item-failed')), findsOneWidget);
    expect(find.text('No se envió. Toca para reintentar.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-item-failed')));
    await tester.pump();

    expect(repo.sends, hasLength(2));
    expect(find.byKey(const Key('chat-item-pending')), findsOneWidget);
  });

  testWidgets('incoming messages appear live', (tester) async {
    final repo = _FakeChatRepository();
    await pumpRouterAt(
      tester,
      '/inbox/conv-1',
      overrides: [chatRepositoryProvider.overrideWithValue(repo)],
    );

    repo.incoming.add(
      _message('m7', 'Voy en camino', DateTime(2026, 10, 1, 9)),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(ManoChatBubble, 'Voy en camino'),
      findsOneWidget,
    );
  });

  testWidgets('with default mocks, the other side replies after sending', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/inbox/conv-1');

    await _type(tester, 'Hola');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ManoChatBubble, 'Hola'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        ManoChatBubble,
        '¡Recibido! Te respondo en un momento.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the inbox opens with a large Mensajes title', (tester) async {
    await pumpRouterAt(tester, '/inbox');

    expect(find.text('Mensajes'), findsOneWidget);
  });

  testWidgets('tapping a Bandeja conversation opens its chat', (tester) async {
    final container = await pumpRouterAt(tester, '/inbox');

    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/inbox/conv-1');
    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });

  testWidgets('leaving the chat refreshes the Bandeja snippet', (tester) async {
    await pumpRouterAt(tester, '/inbox');
    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();

    await _type(tester, 'Hola de nuevo');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(ManoConversationTile, 'Hola de nuevo'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  group('photos', () {
    Future<void> attachFromGallery(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('mano-composer-attach')));
      await tester.pumpAndSettle();
      expect(find.byType(ManoMediaSourceSheet), findsOneWidget);
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a picked photo waits in the composer, then goes out', (
      tester,
    ) async {
      final repo = _FakeChatRepository();
      final picker = FakeMediaPicker();
      await pumpRouterAt(
        tester,
        '/inbox/conv-1',
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          mediaPickerProvider.overrideWithValue(picker),
        ],
      );

      await attachFromGallery(tester);
      expect(picker.sources, [PhotoSource.gallery]);
      expect(
        find.byKey(const Key('mano-composer-attachments')),
        findsOneWidget,
      );
      final send = find.byKey(const Key('mano-composer-send'));
      expect(tester.widget<IconButton>(send).onPressed, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<IconButton>(send).onPressed, isNotNull);
      await tester.tap(send);
      await tester.pump();

      expect(repo.bodies, [photoOnlyCaption]);
      expect(repo.mediaIds.single, hasLength(1));
      expect(find.byKey(const Key('mano-composer-attachments')), findsNothing);
      expect(find.byKey(const Key('chat-bubble-photo')), findsOneWidget);
      expect(find.text(photoOnlyCaption), findsNothing);

      repo.sends.single.complete(const Err(DataUnavailable()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-item-failed')), findsOneWidget);
      expect(find.byKey(const Key('chat-bubble-photo')), findsOneWidget);
    });

    testWidgets('a photo-only message shows the photo, not the caption', (
      tester,
    ) async {
      final repo = _FakeChatRepository(
        history: [
          Message(
            id: 'm1',
            conversationId: 'conv-1',
            body: photoOnlyCaption,
            sentAt: DateTime(2026, 10, 1, 9),
            fromMe: false,
            media: const [MediaAttachment(id: 'md1', url: 'https://x/1.jpg')],
          ),
        ],
      );
      await pumpRouterAt(
        tester,
        '/inbox/conv-1',
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      );

      expect(find.byKey(const Key('chat-bubble-photo')), findsOneWidget);
      expect(find.text(photoOnlyCaption), findsNothing);
    });

    testWidgets('tapping a photo opens it full screen', (tester) async {
      final repo = _FakeChatRepository(
        history: [
          Message(
            id: 'm1',
            conversationId: 'conv-1',
            body: 'La fuga',
            sentAt: DateTime(2026, 10, 1, 9),
            fromMe: false,
            media: const [MediaAttachment(id: 'md1', url: 'https://x/1.jpg')],
          ),
        ],
      );
      await pumpRouterAt(
        tester,
        '/inbox/conv-1',
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
      );

      expect(find.text('La fuga'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-bubble-photo')));
      await tester.pumpAndSettle();
      expect(find.byType(ManoImageViewer), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(ManoImageViewer), findsNothing);
    });
  });
}
