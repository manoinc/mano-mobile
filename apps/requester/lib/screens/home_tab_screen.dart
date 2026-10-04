import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Maps a [ServiceCategory.iconKey] to the icon a chip shows. `mano_ui`
/// cannot see `ServiceCategory`, so this mapping lives here, at the screen
/// that can see both sides. An unrecognized key falls back to a generic
/// icon rather than crashing, so a category the app doesn't know about yet
/// still renders.
const Map<String, IconData> _categoryIcons = {
  'cleaning': Icons.cleaning_services_outlined,
  'plumbing': Icons.plumbing,
  'electrical': Icons.electrical_services,
  'painting': Icons.format_paint_outlined,
  'gardening': Icons.grass,
};

IconData _iconFor(String iconKey) =>
    _categoryIcons[iconKey] ?? Icons.build_outlined;

void _showStub(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Muy pronto')));
}

/// The Inicio tab: a greeting, an address and a search pill, a category
/// rail, and a feed of popular listings the rail filters.
///
/// Nothing here has a real destination yet -- no address picker, no search
/// results, no listing detail -- so every one of those taps shows a stub
/// notice instead of a silent no-op. Only the category filter, which is
/// pure local UI state, is real.
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  String? _selectedCategoryId;

  void _toggleCategory(String id) {
    setState(() {
      _selectedCategoryId = _selectedCategoryId == id ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final signedIn = ref.watch(sessionProvider).value is SignedIn;
    final categories = ref.watch(serviceCategoriesProvider);
    final listings = ref.watch(popularListingsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.md),
          children: [
            // The nav shell is where browsing as a guest lands too --
            // "Omitir" was never meant to be a one-way door, so the way into
            // an account stays one tap away. On its own line, not sharing a
            // row with the greeting: a personalized "Hola, <name>" is
            // variable-length in a way a fixed logo never was, and at a
            // small phone's large text the two competing for one row is
            // exactly the overflow the rest of this app avoids by wrapping.
            if (!signedIn)
              Align(
                alignment: Alignment.centerRight,
                child: ManoTextAction(
                  label: 'Iniciar sesión',
                  onPressed: () =>
                      ref.read(onboardingFlowProvider.notifier).startSignIn(),
                ),
              ),
            ManoGreetingHeader(name: user?.displayName ?? 'Solicitante'),
            const SizedBox(height: ManoSpacing.md),
            // There is no address feature yet, so this is a neutral
            // placeholder label rather than invented data claiming to be the
            // real user's actual address.
            ManoAddressPill(
              address: 'Agrega tu dirección',
              onTap: () => _showStub(context),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoSearchPill(onTap: () => context.push('/home/search')),
            const SizedBox(height: ManoSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Explora por categoría',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                ),
                // `ManoQuietButton` forces a full-width minimum size (it's
                // meant to be a screen's sole secondary action), which does
                // not fit trailing a Row -- so this matches its weight
                // (clay foreground, labelLarge) with a plain TextButton
                // instead of reusing it verbatim.
                TextButton(
                  onPressed: () => _showStub(context),
                  style: TextButton.styleFrom(
                    foregroundColor: ManoColors.clay,
                    textStyle: textTheme.labelLarge,
                  ),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            categories.when(
              data: (items) => ManoCategoryRail(
                items: [
                  for (final category in items)
                    ManoCategoryRailItem(
                      id: category.id,
                      icon: _iconFor(category.iconKey),
                      label: category.label,
                    ),
                ],
                selectedId: _selectedCategoryId,
                onSelected: _toggleCategory,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Text('No se pudo cargar.'),
            ),
            const SizedBox(height: ManoSpacing.lg),
            Text('Populares cerca de ti', style: textTheme.titleMedium),
            const SizedBox(height: ManoSpacing.sm),
            listings.when(
              data: (items) {
                final selected = _selectedCategoryId;
                final visible = selected == null
                    ? items
                    : items
                          .where((listing) => listing.categoryId == selected)
                          .toList();
                return Column(
                  children: [
                    for (final listing in visible) ...[
                      ManoListingCard(
                        title: listing.title,
                        photoUrl: listing.photoUrl,
                        professionalName: listing.professionalName,
                        professionalPhotoUrl: listing.professionalPhotoUrl,
                        priceLabel:
                            'Desde ${ManoFormat.cop(listing.priceFromCents ~/ 100)} COP',
                        rating: listing.rating,
                        onTap: () => _showStub(context),
                      ),
                      const SizedBox(height: ManoSpacing.sm),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Text('No se pudo cargar.'),
            ),
          ],
        ),
      ),
    );
  }
}
