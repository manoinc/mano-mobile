# Navigation Shell

The Mano Requester app's bottom-navigation shell and routing structure.

## Widget Hierarchy

```
RequesterApp (MaterialApp.router)
└─ requesterRouterProvider (GoRouter, redirect: session-aware)
   ├─ /sign-in → SignInScreen
   └─ StatefulShellRoute.indexedStack → NavShell (ManoBottomNavBar + Scaffold)
      ├─ /home → HomeTabScreen
      │          ├─ ManoGreetingHeader
      │          ├─ ManoAddressPill
      │          ├─ ManoSearchPill
      │          ├─ ManoCategoryRail (ManoCategoryRailItem)
      │          └─ ManoListingCard
      ├─ /projects → ProjectsTabScreen
      │              ├─ ManoProjectFilterTabs
      │              └─ ManoProjectCard | ManoEmptyState
      ├─ /inbox → InboxTabScreen
      │            └─ ManoConversationTile
      └─ /profile → ProfileTabScreen
                   ├─ ManoProfileHeader
                   └─ ManoOptionRow

NavShell's ManoBottomNavBar hosts four destinations plus a fifth action:
  - Items[0]: Inicio (home icon) → goBranch(0)
  - Items[1]: Proyectos (work icon) → goBranch(1)
  - Items[2]: Bandeja (chat icon) → goBranch(2)
  - Items[3]: Perfil (person icon) → goBranch(3)
  - Center action (CREATE) → showManoSheet(CreateActionSheet)
    └─ CreateActionSheet
       └─ ManoActionSheet (onClose, actions)
          └─ ManoSheetAction(s) (one stub: "Publicar un trabajo")
```

The CREATE action is not a route; it opens an overlay sheet via `showManoSheet` and never changes the active branch index.

## Mock Data Shapes

All repositories are mock-backed pending a real gateway adapter. Fetch with the providers listed.

### ServiceCategory
| Field | Type | Details |
|-------|------|---------|
| `id` | String | unique identifier |
| `label` | String | display name (e.g., "Limpieza") |
| `iconKey` | String | opaque lookup key (e.g., "cleaning"); the screen maps it to IconData |

**Source:** `MockCatalogRepository`  
**Provider:** `serviceCategoriesProvider` → `List<ServiceCategory>`

### ServiceListing
| Field | Type | Details |
|-------|------|---------|
| `id` | String | unique identifier |
| `title` | String | service name |
| `categoryId` | String | links to ServiceCategory.id |
| `professionalName` | String | provider's display name |
| `professionalPhotoUrl` | String | avatar URL |
| `photoUrl` | String | service photo URL |
| `priceFromCents` | int | minimum price in centavos |
| `currency` | String | ISO 4217 code (default: "COP") |
| `rating` | double? | optional star rating |
| `reviewCount` | int | number of reviews (default: 0) |

**Source:** `MockCatalogRepository`  
**Provider:** `popularListingsProvider` → `List<ServiceListing>`

### Project
| Field | Type | Details |
|-------|------|---------|
| `id` | String | unique identifier |
| `title` | String | job title |
| `professionalName` | String | assigned provider's name |
| `professionalPhotoUrl` | String | provider's avatar URL |
| `status` | ProjectStatus | one of: `scheduled`, `inProgress`, `completed`, `canceled` |
| `scheduledAt` | DateTime | when the work is scheduled |
| `address` | String | job location |
| `priceCents` | int | agreed price in centavos |
| `currency` | String | ISO 4217 code (default: "COP") |

**Source:** `MockProjectRepository`  
**Provider:** `projectsProvider` → `List<Project>`

### Conversation
| Field | Type | Details |
|-------|------|---------|
| `id` | String | unique identifier |
| `participantName` | String | other user's display name |
| `participantPhotoUrl` | String | avatar URL |
| `isOnline` | bool | presence indicator (default: false) |
| `isVerified` | bool | verification badge (default: false) |
| `lastMessage` | String | snippet of latest message |
| `lastMessageAt` | DateTime | when the last message was sent |
| `unreadCount` | int | unread message count (default: 0) |

**Source:** `MockConversationRepository`  
**Provider:** `conversationsProvider` → `List<Conversation>`

### Session & User
| Provider | Type | Purpose |
|----------|------|---------|
| `sessionProvider` | AsyncNotifier → SessionState | current session state (SignedIn/SignedOut) |
| `currentUserProvider` | AuthenticatedUser? | signed-in user or null; convenience accessor |

---

**Mock implementations pending real gateway-backed adapters.** All repositories (`MockCatalogRepository`, `MockProjectRepository`, `MockConversationRepository`) are defined in `packages/mano_data` and bound to their domain ports in `packages/mano_session`. Real adapters arrive as new `src/*` files with no changes above the seam.
