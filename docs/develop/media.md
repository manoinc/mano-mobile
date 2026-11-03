# Media: photos from the phone

Chat photos, project photos, profile photos and portfolio photos all go
through one path: a **picker**, an **uploader** and one **controller** that
screens watch.

```
MediaPicker ──PickedImage──▶ PhotoAttachmentsNotifier ──▶ MediaUploader ──▶ MediaAttachment
 (camera / gallery)           (per UploadTarget)           (gateway or mock)   (id + url)
```

## Domain (`mano_domain/lib/src/media/`)

| Type | What it is |
|---|---|
| `PickedImage` | bytes, MIME type and name of a chosen photo, not yet uploaded. `isSupported` is jpeg/png/webp, the only image types mano-media accepts. |
| `MediaAttachment` | a stored file: `id`, `url`, `mimeType?`, `byteSize?`. Chat URLs live 15 minutes, so never persist one. |
| `UploadTarget` | what the upload is for: `ChatUpload(conversationId)`, `AvatarUpload`, `ProjectPhotoUpload`, `PortfolioUpload`. Each knows its `maxBytes`. |
| `MediaPicker` | port: `pick(PhotoSource.camera \| gallery)` → `PickedImage?` (null when the user backs out). |
| `MediaUploader` | port: `upload(PickedImage, UploadTarget)` → `Result<MediaAttachment, DataFailure>`. |

`Message.media` holds a message's photos, and `ChatRepository.send` takes
`mediaIds`. `ProjectDraft.photoUrls` carries a project's photos to `publishProject`.

## Adapters (`mano_data/lib/src/media/`)

- **`GatewayMediaUploader`** runs the mano-media three-step flow:
  1. `requestChatMediaUpload(chatId, contentType)` or
     `requestAvatarUpload(contentType)` → `MediaUploadTicket { mediaId uploadUrl headers { name value } expiresIn }`
  2. `PUT uploadUrl`, sending the ticket's `headers` **verbatim** (the SigV4
     signature covers `Content-Type`) and the raw bytes as the body. This goes
     straight to Garage; bytes never pass through the gateway.
  3. `finalizeMediaUpload(mediaId)` → `Media { mediaId mimeType byteSize url }`.

  The type and size cap are checked before any call. A failed PUT is
  `DataUnavailable`; a refused finalize (`ObjectTooLarge`, `ObjectMissing`) is
  `DataRejected`. Targets the gateway has no upload kind for yet
  (`ProjectPhotoUpload`, `PortfolioUpload`) go to the `unsupported` uploader it
  is given, which is the mock in the app.
- **`ImagePickerMediaPicker`** wraps `image_picker`, asking for `maxWidth 1600` and
  `imageQuality 80` (which keeps an avatar under its 2 MiB cap) and
  `requestFullMetadata: false`. On mobile the plugin rarely reports a MIME type,
  so it is read from the file extension; HEIC comes back as `image/heic` and
  is refused as unsupported.
- **`MockMediaUploader`** + **`MockMediaLibrary`** run offline. They apply the
  same type and size rules, and stand a stock photo in for the user's bytes.
  The mock chat resolves sent `mediaIds` through the same library.

## Session (`mano_session/lib/src/media/`)

- `mediaPickerProvider`, `mediaUploaderProvider` (live gateway with a mock
  fallback; all mock when `offlineMarketplaceProvider`).
- `photoAttachmentsProvider(UploadTarget)` is an autoDispose family notifier.
  It holds `List<PhotoAttachment>` (each `uploading | done | failed`, keeping
  the local bytes so the photo shows at once) and offers `pick`, `retry`,
  `remove` and `clear`, plus `mediaIds`, `urls`, `isUploading` and `isReady`
  (nothing uploading or failed). A photo
  removed while uploading stays removed.

## UI (`mano_ui`)

| Widget | Use |
|---|---|
| `ManoMediaSourceSheet` | "Agregar foto": Elegir de la galería / Tomar foto. Show it with `showManoSheet`. |
| `ManoPhotoPickerGrid` | square tiles with uploading and failed overlays, remove and retry, and a dashed add tile that disappears at `maxPhotos`. Takes `ManoPickedPhoto { id, ImageProvider image, status }`, so the screen maps `PhotoAttachment` to `MemoryImage(bytes)`. |

| `ManoImageViewer` | a photo full screen, opened by `ManoChatThread` and by `ManoPhotoGallery(expandable: true)`. |

The composer's "+" and pending strip, photo bubbles and the viewer are covered
in [MEDIA-01](../modules/MEDIA-01-chat-photos.md).

!!! note "A photo needs text"
    chatservice refuses `sendMessage` with empty `content`, even when `mediaIds` is
    set, and the mock does the same. So a photo sent without text goes out as
    `photoOnlyCaption` ("📷 Foto"), which the bubble hides under the photo. The rule
    lives in `mano_session/lib/src/chat/photo_caption.dart`.

## Limits (mano-media)

| Kind | Types | Max |
|---|---|---|
| AVATAR | jpeg, png, webp | 2 MiB |
| CHAT_ATTACHMENT | jpeg, png, webp (+ mp4, mov on the server; the app sends images only) | 100 MiB |
| WORK_IMAGE, REVIEW_MEDIA | jpeg, png, webp | 10 MiB, **upload stubbed on the gateway** |

## Running it on the phone

The presigned URL points at `MEDIA_BASE_URL`, and SigV4 signs the `Host`, so the
phone must reach exactly that address. Run the local stack from
`mano-gateway/docs/local-stack.md` with `MEDIA_BASE_URL=http://127.0.0.1:3900`, then:

```bash
adb reverse tcp:8082 tcp:8082   # gateway
adb reverse tcp:3900 tcp:3900   # Garage S3, for the PUT and for viewing photos
```

Without the second reverse, ticket and finalize succeed but the PUT fails, so
the photo shows as failed with a retry.
