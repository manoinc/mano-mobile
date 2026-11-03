# MEDIA-01 · Chat photos & project photos

Photos in chat (both apps) and on projects (requester publishes, both apps view).
It builds on the media foundation in [Media](../develop/media.md).

## Chat

| What | Where |
|---|---|
| Attach, pending strip, send | `ManoMessageComposer(onAttach, attachments, onRemoveAttachment, onRetryAttachment, canSend)` |
| Photo bubbles | `ManoChatEntry.photos` → `ManoChatBubble.photos` |
| Full-screen viewer | `ManoImageViewer`, opened by `ManoChatThread` itself |
| State | `ChatThreadNotifier.send` + `photoAttachmentsProvider(ChatUpload(conversationId))` |
| Screens | `apps/{requester,provider}/lib/features/chat/chat_screen.dart` |
| Picking | `apps/<app>/lib/features/media/photo_picking.dart`: `pickPhoto` (the source sheet) and `pickedPhotos` (tiles from local bytes) |

### Flow

1. "+" at the composer's left opens `ManoMediaSourceSheet` (Elegir de la galería / Tomar foto).
   In the provider app a guest gets the account-needed sheet instead, like sending.
2. The photo appears at once in the strip above the field, from its local bytes,
   with a spinner while it uploads. Send is disabled while any photo is uploading
   or failed; a failed one can be retried or removed.
3. `send(text)` reads the composer's photos, clears them, and adds an outgoing item
   that carries them (`OutgoingChatItem.photos`), drawn from local bytes with a
   spinner until the backend confirms. Retry resends the same `mediaIds`.
4. The confirmed message draws `Message.media` URLs (`ConfirmedChatItem.photoUrls`).
   Chat URLs live 15 minutes: they are drawn from the latest read and never kept.
5. Tapping a photo opens `ManoImageViewer`: black ground, pinch to zoom, tap or
   swipe down to close, close button top left, Hero from the bubble.

### The default caption

chatservice refuses `sendMessage` with empty content, even with photos. So a photo
sent without text goes out as `photoOnlyCaption` ("📷 Foto"), and the bubble hides
that caption under photos. Both halves live in
`mano_session/lib/src/chat/photo_caption.dart` (`outgoingBody`, `visibleCaption`);
items expose the result as `ChatThreadItem.caption`.

### Bubble layout

Photos sit above the text, outside the coloured bubble, rounded `ManoRadius.card`:
one photo 4:3 up to 260 dp wide, several in two columns. With no caption the time
and receipt go under the photos in `faint`.

## Project photos

- `PublishProjectScreen` has a photos step between the details and the budget:
  `PhotosStep` with `ManoPhotoPickerGrid` (up to 6) and
  `photoAttachmentsProvider(const ProjectPhotoUpload())`. Optional: "Omitir"
  while empty; "Continuar" waits while a photo uploads.
- The review shows the photos as a part of its own ("1 foto", editable), and
  "Publicar proyecto" stays shut while a photo uploads. Publishing sends
  `draft.copyWith(photoUrls: urls)`.
- The gateway has no upload kind for project photos yet, so `ProjectPhotoUpload`
  goes to the mock uploader and a stock photo URL is published. Expected until
  the backend adds the kind.
- Requester project detail and provider lead detail show `ManoPhotoGallery(expandable: true)`
  under the description when the project has photos; tapping one opens the viewer.

## Tests

- `mano_session`: `test/chat/photo_caption_test.dart`, the `photos` group in
  `test/chat/chat_thread_notifier_test.dart`, `isReady` in `test/media/photo_attachments_test.dart`.
- `mano_ui`: composer, bubble, thread, image viewer and gallery widget tests.
- Apps, through the real router with `FakeMediaPicker` (`test/support/`) and the
  offline mock uploader: chat screen tests in both apps, the guest gate on attach,
  the publish photos step, and the galleries on the detail screens.
- Device: `chat_flow_test.dart` (both apps) and requester `projects_flow_test.dart`.
