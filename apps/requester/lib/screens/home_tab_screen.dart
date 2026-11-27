import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/explore/category_icons.dart';
import '../features/projects/publish_project_row.dart';
import '../features/projects/start_publishing.dart';

// Opens search, filtered to [categoryId] when there is one.
void _openSearch(BuildContext context, [String? categoryId]) => context.push(
  Uri(
    path: '/home/search',
    queryParameters: {'category': ?categoryId},
  ).toString(),
);

/// Height of a carousel card: 16:9 photo, avatar row and a two-line title.
double _listingCardHeight(BuildContext context, double railWidth) {
  const viewportFraction = 0.8;
  final cardWidth = railWidth * viewportFraction - ManoSpacing.sm;
  final body = Theme.of(context).textTheme.bodyMedium!;
  final titleLines = MediaQuery.textScalerOf(context)
      .scale(body.fontSize! * (body.height ?? 1.5) * 2);
  final avatarRow = MediaQuery.textScalerOf(context).scale(28);
  return cardWidth * 9 / 16 +
      ManoSpacing.sm * 2 +
      avatarRow +
      ManoSpacing.xs +
      titleLines +
      ManoSpacing.md;
}

/// The Inicio tab: a greeting (or a neutral headline for guests), an address
/// and a search pill, a category rail, and horizontal rails of listings.
///
/// Search, categories and listing cards open search; the pill opens addresses.
class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final signedIn = ref.watch(hasAccountProvider);
    final categories = ref.watch(serviceCategoriesProvider);
    final sections = ref.watch(homeSectionsProvider);
    final defaultAddress = ref.watch(defaultAddressProvider).value;
    final name = requesterGreetingName(
      user,
      ref.watch(onboardingFlowProvider),
      profileName: signedIn
          ? ref.watch(clientProfileProvider).value?.displayName ?? ''
          : '',
    );
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
            ManoGreetingHeader(name: name),
            const SizedBox(height: ManoSpacing.md),
            ManoAddressPill(
              address: switch (defaultAddress) {
                final a? => '${a.label} · ${a.line}',
                null => 'Agrega tu dirección',
              },
              onTap: () => context.push('/home/addresses'),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoSearchPill(onTap: () => _openSearch(context)),
            PublishProjectRow(onTap: () => startPublishing(context, ref)),
            const SizedBox(height: ManoSpacing.md),
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
                  onPressed: () => _openSearch(context),
                  style: TextButton.styleFrom(
                    foregroundColor: context.palette.clay,
                    textStyle: textTheme.labelLarge,
                  ),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            categories.when(
              data: (items) => ManoCategoryRail(
                items: categoryRailItems(items),
                onSelected: (id) => _openSearch(context, id),
              ),
              loading: () => const ManoSkeletonList(rows: 1),
              error: (error, stackTrace) => const Text('No se pudo cargar.'),
            ),
            const SizedBox(height: ManoSpacing.lg),
            sections.when(
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final section in items) _Rail(section: section),
                ],
              ),
              loading: () => const ManoSkeletonList(rows: 1),
              error: (error, stackTrace) => const Text('No se pudo cargar.'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One titled horizontal rail; its header opens search, filtered when it has a category.
class _Rail extends StatelessWidget {
  const _Rail({required this.section});

  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ManoSectionHeader(
            title: section.title,
            onTap: () => _openSearch(context, section.categoryId),
          ),
          const SizedBox(height: ManoSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) => ManoListingCarousel(
              height: _listingCardHeight(context, constraints.maxWidth),
              children: [
                for (final listing in section.listings)
                  ManoListingCard(
                    title: listing.title,
                    photoUrl: listing.photoUrl,
                    professionalName: listing.professionalName,
                    professionalPhotoUrl: listing.professionalPhotoUrl,
                    priceLabel:
                        'Desde ${ManoFormat.cop(listing.priceFromCents ~/ 100)} COP',
                    rating: listing.rating,
                    // Mock listings have no detail route yet; their category's results stand in.
                    onTap: () => _openSearch(context, listing.categoryId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
