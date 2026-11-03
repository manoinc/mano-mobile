import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_media.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

final class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({this.history = const [], this.failLoads = 0});

  final List<Message> history;
  int failLoads;
  final incoming = StreamController<Message>.broadcast();
  final sends = <Completer<Result<Message, DataFailure>>>[];
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

Future<dynamic> _pumpChat(
  WidgetTester tester, {
  ChatRepository? repo,
  MediaPicker? picker,
}) => pumpRouterAt(
  tester,
  '/inbox/conv-1',
  session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  overrides: [
    if (repo != null) chatRepositoryProvider.overrideWithValue(repo),
    if (picker != null) mediaPickerProvider.overrideWithValue(picker),
  ],
);

void main() {
  testWidgets('the header shows the client and their verified badge', (
    tester,
  ) async {
    await _pumpChat(tester);

    final header = find.byType(ManoChatHeader);
    expect(
      find.descendant(of: header, matching: find.text('Ana Gómez')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: header, matching: find.byIcon(Icons.verified)),
      findsOneWidget,
    );
  });

  testWidgets('an unnamed client is called Cliente in the header', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/inbox/conv-9',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
      overrides: [
        conversationRepositoryProvider.overrideWithValue(
          _OneConversation(
            const Conversation(
              id: 'conv-9',
              participant: Party(id: 'c9', displayName: '', photoUrl: ''),
              participantRole: ManoRole.requester,
            ),
          ),
        ),
      ],
    );

    expect(
      find.descendant(
        of: find.byType(ManoChatHeader),
        matching: find.text('Cliente'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the header opens the participant profile', (
    tester,
  ) async {
    await _pumpChat(tester);

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
    await _pumpChat(tester, repo: repo);

    expect(find.byKey(const Key('chat-receipt-read')), findsOneWidget);
  });

  testWidgets('renders the history with day separators', (tester) async {
    await _pumpChat(
      tester,
      repo: _FakeChatRepository(
        history: [
          _message('m1', 'Hola', DateTime(2026, 10, 1, 9), fromMe: true),
          _message('m2', 'Buenos días', DateTime(2026, 10, 2, 8)),
        ],
      ),
    );

    expect(find.byType(ManoChatBubble), findsNWidgets(2));
    expect(find.text('1 oct'), findsOneWidget);
    expect(find.text('2 oct'), findsOneWidget);
    final mine = tester.widget<ManoChatBubble>(
      find.widgetWithText(ManoChatBubble, 'Hola'),
    );
    expect(mine.mine, isTrue);
  });

  testWidgets('an empty thread invites the first message', (tester) async {
    await _pumpChat(tester, repo: _FakeChatRepository());

    expect(find.text('Escribe el primer mensaje'), findsOneWidget);
    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });

  testWidgets('a failed load shows an error with retry', (tester) async {
    await _pumpChat(
      tester,
      repo: _FakeChatRepository(
        history: [_message('m1', 'Hola', DateTime(2026, 10, 1, 9))],
        failLoads: 1,
      ),
    );

    expect(find.text('No se pudo cargar la conversación.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ManoChatBubble, 'Hola'), findsOneWidget);
  });

  testWidgets('a sent message shows pending, then confirmed', (tester) async {
    final repo = _FakeChatRepository();
    await _pumpChat(tester, repo: repo);

    await _type(tester, 'Voy en camino');
    expect(find.byKey(const Key('chat-item-pending')), findsOneWidget);

    repo.sends.single.complete(
      Ok(
        _message('m5', 'Voy en camino', DateTime(2026, 10, 1, 9), fromMe: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-item-pending')), findsNothing);
    expect(
      find.widgetWithText(ManoChatBubble, 'Voy en camino'),
      findsOneWidget,
    );
  });

  testWidgets('a failed send retries on tap', (tester) async {
    final repo = _FakeChatRepository();
    await _pumpChat(tester, repo: repo);

    await _type(tester, 'Hola');
    repo.sends.single.complete(const Err(DataUnavailable()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-item-failed')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-item-failed')));
    await tester.pump();

    expect(repo.sends, hasLength(2));
    expect(find.byKey(const Key('chat-item-pending')), findsOneWidget);
  });

  testWidgets('incoming messages appear live', (tester) async {
    final repo = _FakeChatRepository();
    await _pumpChat(tester, repo: repo);

    repo.incoming.add(_message('m7', '¿Ya vienes?', DateTime(2026, 10, 1, 9)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ManoChatBubble, '¿Ya vienes?'), findsOneWidget);
  });

  testWidgets('the inbox opens with a large Mensajes title', (tester) async {
    await pumpRouterAt(
      tester,
      '/inbox',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    expect(find.text('Mensajes'), findsOneWidget);
  });

  testWidgets('leaving the chat refreshes the inbox snippet', (tester) async {
    final container = await pumpRouterAt(
      tester,
      '/inbox',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    await tester.tap(find.text('Ana Gómez'));
    await tester.pumpAndSettle();
    expect(routerPath(container), '/inbox/conv-1');

    await _type(tester, 'Hola, voy en camino');
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(ManoChatBubble, 'Hola, voy en camino'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    const reply = '¡Recibido! Te respondo en un momento.';
    expect(find.widgetWithText(ManoChatBubble, reply), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/inbox');
    expect(find.widgetWithText(ManoConversationTile, reply), findsOneWidget);
  });

  testWidgets('a photo from the camera goes out with the message', (
    tester,
  ) async {
    final repo = _FakeChatRepository();
    final picker = FakeMediaPicker();
    await _pumpChat(tester, repo: repo, picker: picker);

    await tester.tap(find.byKey(const Key('mano-composer-attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar foto'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(picker.sources, [PhotoSource.camera]);

    await _type(tester, 'Así quedó');
    expect(repo.mediaIds.single, hasLength(1));
    expect(find.byKey(const Key('chat-bubble-photo')), findsOneWidget);
    expect(find.text('Así quedó'), findsOneWidget);

    repo.sends.single.complete(
      Ok(
        Message(
          id: 'm9',
          conversationId: 'conv-1',
          body: 'Así quedó',
          sentAt: DateTime(2026, 10, 1, 9),
          fromMe: true,
          media: const [MediaAttachment(id: 'md1', url: 'https://x/1.jpg')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-bubble-photo')));
    await tester.pumpAndSettle();
    expect(find.byType(ManoImageViewer), findsOneWidget);
  });
}
