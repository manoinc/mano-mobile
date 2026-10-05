# Polish backlog

Every detail noted while building the 11 basic screens (waves 1–2), grouped by
what kind of change it is. Tick, edit or add to this before the polish pass.

## 1. Visual — both apps

- [ ] **Pinkish surfaces.** The theme derives Material surfaces from the flame
  seed colour. These come out pink instead of the palette's sand (`#f7f5f3`) and
  stone (`#ede9e6`):
  - [ ] cards
  - [ ] unselected filter pills (`ManoProjectFilterTabs`)
  - [ ] status chips' neutral tone
  - [ ] app bars (e.g. "Nueva oferta", "Disponibilidad")
  - [ ] the calendar-link box

  One fix in `mano_theme.dart`, but it touches every screen.
- [ ] **Sheets sit above the bottom nav bar.** Sheets opened inside a tab leave
  the nav bar visible underneath instead of covering it. Seen on the hour logger
  and the requester's request sheets. Likely fix: open them on the root
  navigator.
- [ ] **"Solicitudes" truncates** to "Solicitud…" in the provider bottom nav.
- [ ] **Anonymous offer cards.** Every offer shows a "P" avatar and
  "Profesional". The gateway only returns `offerantId`, with no name, photo or
  rating. Decide the interim look until it does.
- [ ] **Text-only search results.** `JobService` has no photo or starting price.
- [ ] **Client row on job detail.** `ManoPersonRow` requires a rating, which
  clients don't have, so the provider job detail uses a plain avatar row.
  Decide whether `ManoPersonRow` gets an optional rating.

## 2. Content and copy

- [ ] **Raw category ids in the service picker.** The provider offer editor
  shows "painting", "plumbing" and so on instead of Spanish labels; the
  requester already maps them.
- [ ] **"Hola, Solicitante"** is the guest and placeholder greeting on Home.
- [ ] **"Muy pronto" stubs still in place:**
  - [ ] address pill (Home)
  - [ ] popular listing taps (Home)
  - [ ] the create sheet's "Publicar un trabajo" (requester centre button)
- [ ] **Unsorted Activity lists.** Items appear in repository order within each
  filter (REQ-04).

## 3. Behaviour and UX

- [ ] **The inbox doesn't re-sort** after a new message. The conversation stays
  in place instead of moving to the top.
- [ ] **"Escribir a cliente" opens the inbox, not that client's chat** (PROV-04).
  Needs a request → conversation link (domain + mocks).
- [ ] **The hour-logger prefill is wrong** (it showed 9 h). `Job` has no
  `startedAt`, so it counts from the scheduled start (PROV-05). Needs a domain
  field set by `start()`.
- [ ] **Booking slots don't refresh** after a booking, so a just-booked slot can
  still look free until the screen is reopened (REQ-03).
- [ ] **The mock lets you book a taken slot.** `bookSlot` doesn't check that the
  slot is free.
- [ ] **Blocks can't be swiped away.** Calendar blocks are removed with the ×
  only (PROV-03).
- [ ] **Time pickers are dropdowns.** The rule editor uses two 30-minute
  dropdowns; consider a nicer picker (PROV-03).
- [ ] **Search is capped at 50 results.** It fetches the first 50 with no paging
  (REQ-01). Offer filtering and sorting are also client-side (REQ-02).
- [ ] **No sign-out in the provider app.** The placeholder home that had it was
  removed in the foundation.

## 4. Provider onboarding (PROV-01)

- [ ] **No profile photo step.** `WorkerProfileDraft` has no photo field (domain
  change).
- [ ] **"Adjuntar" only records a placeholder.** There is no file or image
  picker yet; adding one means a plugin such as `image_picker` or `file_picker`.
- [ ] **Pending status isn't remembered.** Closing the app sends the provider
  back through onboarding.
- [ ] **Unverified providers aren't gated.** They can still publish services and
  receive requests.
- [ ] **Validation lives in mano_session.** Profile validation sits there; move
  it beside `WorkerProfileDraft` in the domain, like
  `registration_validation.dart`.

## 5. Code tidy-ups

- [ ] **Copied helpers.** Status labels, short price, rate label and the
  load-error view exist in both apps. Find them one shared home (they map domain
  values, so not `mano_ui`).
- [ ] **No single-offer read.** `OfferManagement` has no `offer(id)`, so the
  editor scans `myOffers()`.
- [ ] **Local snackbar workarounds.** PROV-03 and PROV-05 still hide snackbars
  themselves before opening sheets. `showManoSheet` now does it globally, so the
  local calls can go.

## 6. Waiting on the backend (not UI work, listed for completeness)

- [ ] **Category filter strings.** The app's ids (`cleaning`, `plumbing`, …) must
  match what the gateway stores; agree on them.
- [ ] **No auth yet.**
  - [ ] SuperTokens sign-in.
  - [ ] Until then every real user is a guest, and confirming a booking only
    shows the account-needed sheet.
- [ ] **Stubbed or missing gateway operations:**
  - [ ] requests, jobs, availability and chat are stubbed
  - [ ] no calendar-feed operation or `.ics` route
  - [ ] no list-my-offers or resume-offer
  - [ ] no `cancelServiceRequest`
- [ ] **Data isn't scoped to the signed-in user.** Conversations and requests
  aren't scoped by role, so the provider sees the requester's mock conversations.
- [ ] **No idempotency key on `send`.** Chat dedupe relies on the server
  returning the same message id from `send` and `watch`; an idempotency key
  would make it safe.
- [ ] **Cancel reasons are dropped** by the job mock, and the gateway contract
  should store them.
