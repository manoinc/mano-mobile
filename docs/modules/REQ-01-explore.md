# REQ-01 · Explore (requester)

Search the public catalog and open a service. Guests can do all of it: nothing
here reads the session.

## Screens

| Screen | File | Route |
|---|---|---|
| Search | `apps/requester/lib/features/explore/search_screen.dart` | `/home/search?category=<id>` |
| Service detail | `apps/requester/lib/features/explore/service_detail_screen.dart` | `/home/service/:id` |

Shared screen helpers live in `features/explore/category_icons.dart`. They hold
the `iconKey` → `IconData` map, the `ServiceCategory` → `ManoCategoryRailItem`
mapping, and `categoryLabel()`, which shows our label for a gateway category id
and falls back to the raw string. The home tab reuses them.

### Search

- An autofocused `ManoSearchField` sits in the app bar. Each keystroke restarts
  a 300 ms timer, and the query only changes when that timer fires.
- The `ManoCategoryRail` filters by `ServiceCategory.id`. Tapping the selected
  chip clears the filter. The `?category=` route parameter preselects a chip.
- An empty query lists everything the catalog returns (the gateway caps it at 50).
- Each result shows its category label (clay), title and a 2-line description.
  Tapping one does `context.push('/home/service/<id>')`.
- The states are loading (a spinner), error ("No pudimos cargar los servicios." with
  **Reintentar**) and empty ("No encontramos servicios con esa búsqueda…" with
  **Limpiar búsqueda**, which resets the text and the category). A previous
  result stays visible while the next one loads (`skipLoadingOnReload`).

### Service detail

- Shows the category label, the title (`headlineSmall`) and the full description.
- One flame CTA, **Ver ofertas**, pinned to the bottom, pushes
  `/home/service/<id>/offers` (REQ-02).
- When the service id is unknown (`null`), a not-found state appears ("No
  encontramos este servicio…"). Its button pops back, or goes to
  `/home/search` when there is nothing to pop. No CTA is shown.
- If loading fails, an error state with **Reintentar** appears, which
  invalidates `jobServiceProvider(id)`.

### Home entry points (`screens/home_tab_screen.dart`)

- The search pill and **Ver todo** both go to `/home/search`.
- Tapping a category goes to `/home/search?category=<id>`. The old local
  filter on popular listings is gone, so the home tab is now a stateless
  `ConsumerWidget`.

## State flow

`packages/mano_session/lib/src/explore/service_search.dart`:

```dart
final class ServiceQuery {
  const ServiceQuery({this.category, this.text = ''});  // raw input
  String? get categoryFilter;   // trimmed, blank → null
  String? get searchText;       // trimmed, blank → null
  ServiceQuery copyWith({String? Function()? category, String? text});
}

final serviceSearchProvider =
    FutureProvider.autoDispose.family<List<JobService>, ServiceQuery>(...);
```

- Two queries are equal when their normalized filters are equal, so
  `'aseo '` and `' aseo'` share one provider instance.
- The screen keeps the current `ServiceQuery` in its own `State`, because the
  debounce is a presentation concern. It watches `serviceSearchProvider(query)`.
- `autoDispose` drops results for queries the user has moved past.
- Riverpod 3's automatic retry is **off** for this provider
  (`retry: (_, _) => null`). With retry on, a gateway failure would spin for up
  to about 30 s before the error appeared. Here the user gets **Reintentar**
  right away, and it calls `ref.invalidate(serviceSearchProvider(query))`.
- Detail reads the shared `jobServiceProvider(id)`, which keeps the default
  retry.
- Category names and icons come from `serviceCategoriesProvider` (mock), because
  the gateway has no list-categories query.
- Nothing in this module mutates data, so it invalidates nothing beyond its own
  retries.

## Ports and adapters

| Port | Provider | Adapter |
|---|---|---|
| `ServiceCatalog.search(category:, text:)` | `serviceSearchProvider` | `GatewayServiceCatalog` (live) |
| `ServiceCatalog.service(id)` | `jobServiceProvider` | `GatewayServiceCatalog` (live) |
| `CatalogRepository.categories()` | `serviceCategoriesProvider` | `MockCatalogRepository` |

## Shared widgets added

`ManoSearchField` (`packages/mano_ui/lib/src/widgets/mano_search_field.dart`) is
the real input behind `ManoSearchPill`, drawn as the same sand pill. It shows a
clear button ("Borrar") once there is text.

```dart
ManoSearchField({
  required TextEditingController controller,
  ValueChanged<String>? onChanged,
  bool autofocus = false,
  String hintText = '¿Qué necesitas hoy?',
})
```

## Tests

| Suite | File | Count |
|---|---|---|
| session | `packages/mano_session/test/explore/service_search_test.dart` | 6 |
| ui | `packages/mano_ui/test/widgets/mano_search_field_test.dart` | 4 |
| requester | `apps/requester/test/features/explore/search_screen_test.dart` | 8 |
| requester | `apps/requester/test/features/explore/service_detail_screen_test.dart` | 4 |
| requester | `apps/requester/test/screens/home_tab_screen_test.dart` (entry points) | 3 new, 2 removed |
| device | `apps/requester/integration_test/explore_flow_test.dart` | 1 |

The flow test goes Home → search pill → type "fuga" → tap the result → detail →
**Ver ofertas**, and checks it lands on `/home/service/s2/offers`. It overrides
`serviceCatalogProvider` with `FakeServiceCatalog`
(`test/features/explore/fake_service_catalog.dart`), so it does not need the
gateway.

## Backend gaps

- **Categories.** The gateway has no list-categories query, and `category` is
  an exact-match free-text filter. The chip ids (`cleaning`, `plumbing`, …)
  only match if the gateway stores those same strings. Until a categories
  query exists, or the ids are agreed on, a category filter against live data
  may return nothing.
- **Images and price.** `JobService` has no photo and no "from" price, so
  results are text only. Popular listings on home still come from the mock
  `CatalogRepository`, and tapping them still shows "Muy pronto".
- **Paging.** Search asks for the first 50. There is no paging or infinite scroll.
