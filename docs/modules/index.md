# Screen modules

Each module owns `apps/<app>/lib/features/<folder>/` plus its tests and doc. Its
routes are already registered, so a module never edits the router.

## Requester (`apps/requester`)

| ID | Module | Folder | Routes | Ports | Doc |
|---|---|---|---|---|---|
| REQ-01 | Explore | `explore/` | `/home/search?category=`, `/home/service/:id` | `ServiceCatalog` (live) | [REQ-01](REQ-01-explore.md) |
| REQ-02 | Offers List | `offers/` | `/home/service/:id/offers` | `ServiceCatalog` (live) | [REQ-02](REQ-02-offers.md) |
| REQ-03 | Booking Flow | `booking/` | `/home/book/:offerId` (full screen) | `ServiceCatalog`, `AvailabilityRepository`, `JobRepository`, `ServiceRequestRepository` | [REQ-03](REQ-03-booking.md) |
| REQ-04 | Activity | `activity/` + `screens/projects_tab_screen.dart` | `/projects`, `/projects/job/:id` | `ServiceRequestRepository`, `JobRepository` | [REQ-04](REQ-04-activity.md) |
| REQ-05 | Inbox & Chat | `chat/` + `screens/inbox_tab_screen.dart` | `/inbox`, `/inbox/:conversationId` (full screen) | `ConversationRepository`, `ChatRepository` | [REQ-05](REQ-05-chat.md) |
| REQ-06 | Projects & Quotes | `projects/` | `/publish?category=` (full screen), `/projects?segment=proyectos`, `/projects/project/:id` | `ProjectRepository` (live) | [REQ-06](REQ-06-projects.md) |

## Provider (`apps/provider`)

| ID | Module | Folder | Routes | Ports | Doc |
|---|---|---|---|---|---|
| PROV-01 | Professional Onboarding | `onboarding/` | shown by the root when signed out | `ProviderOnboardingRepository` | [PROV-01](PROV-01-onboarding.md) |
| PROV-02 | My Services & Offers | `services/` | `/services`, `/services/new`, `/services/offer/:id` | `OfferManagement`, `ServiceCatalog` | [PROV-02](PROV-02-services.md) |
| PROV-03 | Availability & Calendar | `availability/` | `/services/availability` | `AvailabilityRepository` | [PROV-03](PROV-03-availability.md) |
| PROV-04 | Incoming Requests | `requests/` | `/requests` | `ServiceRequestRepository` | [PROV-04](PROV-04-requests.md) |
| PROV-05 | Jobs Agenda | `agenda/` | `/agenda`, `/agenda/job/:id` | `JobRepository` | [PROV-05](PROV-05-agenda.md) |
| PROV-06 | Inbox & Chat | `chat/` | `/inbox`, `/inbox/:conversationId` | `ConversationRepository`, `ChatRepository` | [PROV-06](PROV-06-chat.md) |
| PROV-07 | Open Projects & Quotes | `projects/` + `home/home_segments.dart` | `/home` (Proyectos, Mis cotizaciones), `/home/project/:id` | `LeadRepository` (live) | [PROV-07](PROV-07-projects.md) |

## Shared

| ID | Module | Folders | Ports | Doc |
|---|---|---|---|---|
| MEDIA-01 | Chat photos & project photos | `chat/`, `media/` and `projects/` in both apps | `MediaPicker`, `MediaUploader`, `ChatRepository`, `ProjectRepository` | [MEDIA-01](MEDIA-01-chat-photos.md) |
| REVIEWS-01 | Rating flows | `activity/`, `agenda/`, `profile/` | `ReviewRepository` (live) | [REVIEWS-01](REVIEWS-01-rating-flows.md) |

Shared state goes in `mano_session/lib/src/<module>/`:

- REQ-04 builds the jobs/requests notifiers that PROV-04 and PROV-05 reuse.
- REQ-05 builds the chat notifier that PROV-06 reuses.
