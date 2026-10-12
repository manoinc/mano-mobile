import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/explore/category_icons.dart';

void _showStub(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Muy pronto')));
}

/// Height of a carousel card: 16:9 photo, avatar row and a two-line title.
double _listingCardHeight(BuildContext context, double railWidth) {
  const viewportFraction = 0.8;
  final cardWidth = railWidth * viewportFraction - ManoSpacing.sm;
  final body = Theme.of(context).textTheme.bodyMedium!;
  final titleLines = MediaQuery.textScalerOf(
    context,
  ).scale(body.fontSize! * (body.height ?? 1.5) * 2);
  final avatarRow = MediaQuery.textScalerOf(context).scale(28);
  return cardWidth * 9 / 16 +
      ManoSpacing.sm * 2 +
      avatarRow +
      ManoSpacing.xs +
      titleLines +
      ManoSpacing.md;
}

/// The Inicio tab: a greeting, an address and a search pill, a category
/// rail, and a feed of popular listings.
///
/// Search, "Ver todo" and the category rail lead into Explore (REQ-01). The
/// address picker and listing detail don't exist yet, so those taps show a
/// stub notice instead of a silent no-op.
class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onPressed: () => context.push('/home/search'),
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
                items: categoryRailItems(items),
                onSelected: (id) => context.push(
                  Uri(
                    path: '/home/search',
                    queryParameters: {'category': id},
                  ).toString(),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Text('No se pudo cargar.'),
            ),
            const SizedBox(height: ManoSpacing.lg),
            Text('Populares cerca de ti', style: textTheme.titleMedium),
            const SizedBox(height: ManoSpacing.sm),
            listings.when(
              data: (items) => LayoutBuilder(
                builder: (context, constraints) => ManoListingCarousel(
                  height: _listingCardHeight(context, constraints.maxWidth),
                  children: [
                    for (final listing in items)
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
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Text('No se pudo cargar.'),
            ),
          ],
        ),
      ),
    );
  }
}
