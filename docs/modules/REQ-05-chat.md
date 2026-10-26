# REQ-05 · Inbox & Chat (Requester)

## Screens and routes

| Route | Screen | Notes |
|---|---|---|
| `/inbox` | `InboxTabScreen` (`apps/requester/lib/screens/inbox_tab_screen.dart`) | Bandeja tab. Conversation list with pull-to-refresh; tapping a tile pushes `/inbox/<id>`. |
| `/inbox/:conversationId` | `ChatScreen` (`apps/requester/lib/features/chat/chat_screen.dart`) | Full screen, above the nav bar (`parentNavigatorKey: rootKey`). |

`ChatScreen` is made of:

- **App bar.** `ManoChatHeader` (avatar with the online dot, name, clay verified badge). It reads `conversationsProvider` and stays blank until that list resolves.
- **Thread.** `ManoChatThread` from `mano_ui`; the screen only maps each `ChatThreadItem` to a `ManoChatEntry` (`sent`, `pending` or `failed`). See [PROV-06](PROV-06-chat.md#shared-widgets) for the widget's behaviour: reversed list, day separators, "Enviando…", tap-to-retry.
- **Composer.** `ManoMessageComposer` sits at the bottom of a `Column` inside `SafeArea(top: false)`. The Scaffold resizes for the keyboard, so the composer stays above it.
- **Leaving.** A `PopScope` invalidates `conversationsProvider` on pop, so Bandeja shows the latest snippet.
- **States.**
  - Loading: a spinner.
  - Empty: "Escribe el primer mensaje", with the composer still shown.
  - Error: `ManoEmptyState` "No se pudo cargar la conversación." with "Reintentar", which invalidates the thread.

Bandeja is built on `ManoRefreshList` with `ManoFormat.relative` timestamps; its load error offers "Reintentar". A conversation without messages has no time label and reads "Sin mensajes aún" (`preview`); a participant without a name reads "Profesional" or "Cliente" by role (`participantLabel`), in Bandeja and in the chat header.

Chats start from a job: "Escribir" in the job detail calls `conversationActionsProvider.open(jobId:)`, which finds or creates the conversation, invalidates `conversationsProvider` and returns the id to push.

## State flow

Shared state lives in `packages/mano_session/lib/src/chat/` and has no app-specific code, so PROV-06 can reuse it as is.

- `ChatThreadItem` (sealed UI-state value, not domain):
  - `ConfirmedChatItem(Message message)`
  - `OutgoingChatItem({localId, body, sentAt, failed = false})`, with `copyWith({failed})`

  Both expose `body`, `sentAt` and `fromMe`.
- `chatThreadProvider`: `AsyncNotifierProvider.autoDispose.family<ChatThreadNotifier, List<ChatThreadItem>, String /* conversationId */>`. `retry` is disabled because the screen offers its own retry, and Riverpod 3's silent auto-retry would hide the error.
- `ChatThreadNotifier`:
  - `build()`:
    1. Subscribes to `ChatRepository.watch(id)` first, so nothing is lost between history and the live stream, and cancels the subscription in `ref.onDispose`.
    2. Loads `messages(id)`.
    3. Merges in any messages that arrived during the load, deduplicated by id.
    4. Fires `markRead(id)`. On `Ok` it invalidates `conversationsProvider`, so Bandeja's unread badges refresh.
  - `send(text)`: trims the text and ignores blanks. It appends a pending `OutgoingChatItem`, then awaits `ChatRepository.send`.
    - `Ok(message)`: the pending item is removed and the message is added as confirmed, unless that id is already present.
    - `Err`: the item becomes `failed`.
  - `retry(localId)`: moves a failed item back to pending and sends it again.
  - Incoming stream messages are added only if their id is new. A message that arrives both on `watch` and as the `send` result therefore renders once.
  - Item order: confirmed messages in arrival order, then outgoing ones.
  - `ref.mounted` guards every write that follows an await.

What invalidates what:

| Trigger | Invalidates |
|---|---|
| Chat opened (thread built) and `markRead` succeeds | `conversationsProvider` |
| Leaving the chat (pop) | `conversationsProvider` |
| Pull-to-refresh in Bandeja | `conversationsProvider` (`ref.refresh(...future)`) |
| "Reintentar" on a load error | `chatThreadProvider(id)` |
| Leaving the chat | `chatThreadProvider(id)` auto-disposes; the `watch` subscription is cancelled |

## Ports and adapters

| Port | Provider | Default adapter |
|---|---|---|
| `ConversationRepository` | `conversationRepositoryProvider` / `conversationsProvider` | `MockConversationRepository` |
| `ChatRepository` | `chatRepositoryProvider` | `MockChatRepository(replyDelay: 2 s)`: echoes my message on `watch`, then replies "¡Recibido! Te respondo en un momento." |

## Shared widgets

PROV-06 extracted `ManoChatThread`, `ManoChatHeader`, `ManoRefreshList` and `ManoFormat.relative` from this module; both apps now use them, plus `ManoMessageComposer`, `ManoConversationTile` and `ManoEmptyState`.

## Tests

- `packages/mano_session/test/chat/chat_thread_notifier_test.dart` (9 tests):
  - history loads
  - load error (no auto-retry)
  - markRead plus conversations refetch
  - live incoming messages
  - pending → confirmed
  - stream/send dedupe
  - failed send and retry
  - blank sends ignored
  - subscription cancelled on dispose
- `apps/requester/test/features/chat/chat_screen_test.dart` (10 tests):
  - header name and verified badge
  - bubbles, day separators and time labels
  - empty state
  - error and retry
  - pending → confirmed
  - failed send and tap-to-retry
  - live incoming message
  - default mock reply after about 2 s
  - Bandeja tile opens `/inbox/conv-1`
  - leaving the chat refreshes the Bandeja snippet
- `apps/requester/test/screens/inbox_tab_screen_test.dart`: two pull-to-refresh tests, one for a populated list and one for an empty list.
- `apps/requester/integration_test/chat_flow_test.dart` (device test), signed in with the default mocks: Bandeja → first conversation → "Hola" → bubble → simulated reply within about 3 s.

## Backend gaps blocking go-live

- Both ports have gateway adapters (D7, see `docs/develop/backend-contract.md`); `watch` rides the `messageAdded` subscription.
- Offline, `MockConversationRepository.open` doesn't know the job's other side, so a job chat's participant is a blank professional.
- The mocks share state in memory only (`MockChatRepository` updates `MockConversationRepository` on read and on each message), so nothing survives a restart until real adapters back both ports.
- `Message` has no client-generated id or delivery status. Dedupe relies on the server returning the same id on `send` and on `watch`. An idempotency key on `send` would make retries safe against duplicate delivery.
