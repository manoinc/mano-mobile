# PROV-06 · Inbox & Chat (Provider)

The provider's Bandeja and chat behave exactly like the requester's ([REQ-05](REQ-05-chat.md)). The presentational parts now live in `mano_ui`, and each app's screens only map `mano_session` state onto them.

## Screens and routes

| Route | Screen | Notes |
|---|---|---|
| `/inbox` | `ProviderInboxScreen` (`apps/provider/lib/features/chat/provider_inbox_screen.dart`) | Bandeja tab. Tapping a tile pushes `/inbox/<id>`. |
| `/inbox/:conversationId` | `ChatScreen` (`apps/provider/lib/features/chat/chat_screen.dart`) | Full screen, above the nav bar (`parentNavigatorKey: rootKey`). |

**Bandeja**
- A `ManoRefreshList` of `ManoConversationTile`s: pull-to-refresh, hairline dividers, and `ManoFormat.relative` timestamps ("5m", "3h", "2d"). The unread badge comes from `Conversation.unreadCount`.
- Loading: a spinner.
- Empty: "Aún no tienes conversaciones con clientes" (still pullable).
- Error: `ManoEmptyState` "No se pudo cargar tu bandeja." with "Reintentar", which invalidates `conversationsProvider`.
- A conversation without messages has no time label and reads "Sin mensajes aún"; an unnamed client reads "Cliente" (`participantLabel`), here and in the chat header.
- Chats start from the agenda job's "Escribir" (`conversationActionsProvider.open(jobId:)`), see [PROV-05](PROV-05-agenda.md).

**Chat**
- App bar: `ManoChatHeader` (avatar with the online dot, name, verified badge), read from `conversationsProvider`.
- Thread: `ManoChatThread`, with each `ChatThreadItem` mapped to a `ManoChatEntry`:
  - `ConfirmedChatItem` → `sent`, id = message id, `mine` = `fromMe`.
  - `OutgoingChatItem` → `pending` or `failed`, id = `localId`, `mine: true`.
- Composer: `ManoMessageComposer` at the bottom of a `Column` in `SafeArea(top: false)`. The Scaffold resizes for the keyboard.
- Leaving: a `PopScope` invalidates `conversationsProvider` on pop, so Bandeja shows this chat's latest message as the snippet.
- Loading: a spinner. Empty: "Escribe el primer mensaje" with the composer. Error: `ManoEmptyState` "No se pudo cargar la conversación." with "Reintentar", which invalidates `chatThreadProvider(id)`.

## State flow

No new state. The module reuses REQ-05's providers from `packages/mano_session/lib/src/chat/` unchanged; see [REQ-05 · State flow](REQ-05-chat.md#state-flow) for `ChatThreadNotifier` (`send`, `retry`, live `watch`, `markRead`).

| Trigger | Invalidates |
|---|---|
| Chat opened and `markRead` succeeds | `conversationsProvider` (inside the notifier) |
| Leaving the chat (pop) | `conversationsProvider` |
| Pull-to-refresh in Bandeja | `conversationsProvider` (`ref.refresh(...future)`) |
| "Reintentar" in Bandeja | `conversationsProvider` |
| "Reintentar" on a chat load error | `chatThreadProvider(id)` |
| Leaving the chat | `chatThreadProvider(id)` auto-disposes and cancels its `watch` subscription |

## Ports and adapters

| Port | Provider | Default adapter |
|---|---|---|
| `ConversationRepository` | `conversationRepositoryProvider` / `conversationsProvider` | `MockConversationRepository` |
| `ChatRepository` | `chatRepositoryProvider` | `MockChatRepository(replyDelay: 2 s)`, sharing the mock inbox: it records each message as the conversation's last message and clears unread on `markRead`. |

## Shared widgets

Extracted from the requester so neither app duplicates them. Both apps use them now.

- `ManoChatThread({required List<ManoChatEntry> entries, required String emptyMessage, required ValueChanged<String> onRetry})`
  - Entries are oldest first. The list is reversed, so it opens on, and stays pinned to, the newest message.
  - Adds a `ManoFormat.dayMonth` label whenever the day changes, and uses `ManoFormat.time` as the bubble's time label.
  - `pending`: faded bubble reading "Enviando…" (`Key('chat-item-pending')`).
  - `failed`: faded bubble plus "No se envió. Toca para reintentar."; tapping calls `onRetry(entry.id)` (`Key('chat-item-failed')`).
  - No entries: an icon and `emptyMessage`.
- `ManoChatEntry({required String id, required String text, required DateTime sentAt, bool mine = false, ManoChatEntryStatus status = sent})` with `enum ManoChatEntryStatus { sent, pending, failed }`.
- `ManoChatHeader({required String name, required String? photoUrl, required bool online, required bool verified})`
- `ManoRefreshList({required List<Widget> children, required String emptyMessage, required Future<void> Function() onRefresh})`: always scrollable, so empty or short lists can still be pulled.
- `ManoFormat.relative(DateTime at, DateTime now)`: "5m" / "3h" / "2d", never below 1 of the unit; a future timestamp reads "1m".

## Tests

- `packages/mano_ui/test/widgets/mano_chat_thread_test.dart` (5 tests): day labels and times, pending, failed + retry by id, empty, header badge.
- `packages/mano_ui/test/widgets/mano_refresh_list_test.dart` (3 tests): dividers, pull-to-refresh, empty and pullable.
- `packages/mano_ui/test/format/mano_format_test.dart`: two `relative` tests (boundaries, future).
- `apps/provider/test/features/chat/chat_screen_test.dart` (8 tests): header, history and day separators, empty, load error and retry, pending → confirmed, failed send and tap-to-retry, live incoming, and the full loop with default mocks (send, reply after ~2 s, back, the snippet shows the reply).
- `apps/provider/test/features/chat/provider_inbox_screen_test.dart` (6 tests): snippets and relative times, unread badge, pull-to-refresh, provider empty copy, error and retry, tile opens the chat.
- `apps/provider/integration_test/chat_flow_test.dart` (device test), signed in with the default mocks: Bandeja → first conversation → "Hola, voy en camino" → bubble → simulated reply within ~3 s → back → the reply is the snippet.

## Backend gaps blocking go-live

Same as REQ-05. Offline, the conversation list is not role-aware either: a provider sees the same mock conversations as a requester until the backend scopes conversations to the signed-in user.
