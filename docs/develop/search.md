# Search

The requester's search screen (`/home/search`, `apps/requester/lib/features/explore/search_screen.dart`)
follows Taskrabbit's: a back chevron and a rounded pill reading
"¿Con qué necesitas ayuda?" at the top, and below it a two-column grid of
category tiles, each a square photo with its name beside it.

## How it behaves

| State | What shows |
|---|---|
| Nothing typed, no category | The category grid. No call to the gateway. |
| A tile tapped, or `?category=<id>` in the route | The category rail with that chip selected, and the live results for it. |
| Text typed (debounced 300 ms) | Live results from `jobServices(category, searchText)`, filtered by the selected chip if any. |
| Waiting on the gateway | `ManoLoader`, centred. |
| No matches | An empty state whose "Limpiar búsqueda" returns to the grid. |
| Gateway error | An empty state with "Reintentar". |

Tapping the selected chip again, or clearing the text with no category, goes
back to the grid. A result opens `/home/service/<id>`.

Categories are still the static `ServiceCategories` list in `mano_domain`; the
gateway has no category query yet. Results are live (`serviceSearchProvider`
over `GatewayServiceCatalog`).

## Home

Every way into search from Inicio goes through one helper in
`home_tab_screen.dart`: the search pill and "Ver todo" open it unfiltered; a
category chip, a rail header or a listing card open it filtered to that
category. Listing cards come from `MockCatalogRepository` and have no detail
route, so their category's live results stand in for one.

## Category photos

One photo per category, bundled with the requester app in
`apps/requester/assets/categories/<id>.jpg` (400 x 400, under 80 KB each) and
mapped in `category_photos.dart`. A category without a photo falls back to its
icon on stone. `mano_ui` ships none of them: `ManoCategoryTile` takes the photo
as a `Widget`.

All five are from [Unsplash](https://unsplash.com) under the
[Unsplash License](https://unsplash.com/license): free for commercial use,
attribution appreciated but not required. **Pending approval.**

| Category | File | Photo | Photographer |
|---|---|---|---|
| Limpieza | `cleaning.jpg` | [A woman mops a bright living room floor](https://unsplash.com/photos/a-woman-mops-a-bright-modern-living-room-floor-2NcTLdFHpH8) | Vitaly Gariev ([@silverkblack](https://unsplash.com/@silverkblack)) |
| Plomería | `plumbing.jpg` | [A man working on a pipe in a cabinet](https://unsplash.com/photos/a-man-working-on-a-pipe-in-a-cabinet-wzIjLL4KB-4) | Timur Shakerzianov ([@shaker_jpg](https://unsplash.com/@shaker_jpg)) |
| Electricidad | `electrical.jpg` | [Electrician working on an electrical panel](https://unsplash.com/photos/electrician-working-on-electrical-panel-GXLPLG3_Vf4) | Raze Solar ([@razesolar](https://unsplash.com/@razesolar)) |
| Pintura | `painting.jpg` | [A person using a paint roller to paint a wall](https://unsplash.com/photos/a-person-using-a-paint-roller-to-paint-a-wall-rMVjOX8nm2U) | Andrew Itaga ([@and73w](https://unsplash.com/@and73w)) |
| Jardinería | `gardening.jpg` | [Person pruning a juniper bush with shears](https://unsplash.com/photos/person-pruning-juniper-bush-with-shears-PKcTuA_CRAo) | Crystal Jo ([@crystalsjo](https://unsplash.com/@crystalsjo)) |

To replace one, keep the file name, crop it square at 400 px and keep it under
80 KB; `category_photos_test.dart` checks the size.

## References

Taskrabbit's "I need help with" home (search pill over category photos and
pills), Urban Company's service grid, and Uber's category row, all on Mobbin.
