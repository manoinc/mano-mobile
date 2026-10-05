# Navigation

Both apps use `go_router` with a `StatefulShellRoute`: four tabs keep their own
history, and the centre **+** is an action, not a tab. Who reaches the router at
all (signed in, guest or onboarding) is decided *before* it mounts, by each
app's root. There are no redirects.

## Requester (`apps/requester/lib/shell/app_router.dart`)

```
/home                              HomeTabScreen
  /home/search?category=           SearchScreen          REQ-01
  /home/service/:id                ServiceDetailScreen   REQ-01
  /home/service/:id/offers         OffersScreen          REQ-02
  /home/book/:offerId     [root]   BookingScreen         REQ-03
/projects   ("Actividad")          ProjectsTabScreen     REQ-04
  /projects/job/:id                JobDetailScreen       REQ-04
/inbox                             InboxTabScreen        REQ-05
  /inbox/:conversationId  [root]   ChatScreen            REQ-05
/profile                           ProfileTabScreen
+  → CreateActionSheet (a sheet, not a route)
```

Root: `ManoRoot` (`lib/root.dart`) shows the tour, sign-in, registration, or the
shell for signed-in users and guests.

## Provider (`apps/provider/lib/shell/provider_router.dart`)

```
/requests                          RequestsScreen        PROV-04
/agenda                            AgendaScreen          PROV-05
  /agenda/job/:id                  AgendaJobScreen       PROV-05
/inbox                             ProviderInboxScreen   PROV-06
  /inbox/:conversationId  [root]   ChatScreen            PROV-06
/services                          MyServicesScreen      PROV-02
  /services/availability           AvailabilityScreen    PROV-03
  /services/new           [root]   OfferEditorScreen     PROV-02
  /services/offer/:id     [root]   OfferEditorScreen     PROV-02
+  → /services/new
```

Root: `lib/main.dart` shows `ProfessionalOnboardingScreen` when signed out
(PROV-01), then the shell.

`[root]` routes open on the root navigator and cover the bottom bar (booking,
chat, the offer editor).

## Navigating

```dart
context.push('/home/service/$id');   // deeper, keeps back
context.go('/agenda');               // switch tab
```

Routes are registered once, centrally. A module replaces its screen classes but
never edits the router.
