import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Turns cents into "Desde $80.000 COP": Colombian pesos, thousands
/// separated by dots. `ManoListingCard` takes a pre-formatted label because
/// this formatting needs a locale, which is a screen concern, not a widget
/// one.
String _copLabel(int priceFromCents) {
  final pesos = priceFromCents ~/ 100;
  final digits = pesos.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return 'Desde \$$grouped COP';
}

void _showStub(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Muy pronto')));
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
    final categories = ref.watch(serviceCategoriesProvider);
    final listings = ref.watch(popularListingsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.md),
          children: [
            ManoGreetingHeader(name: user?.displayName ?? 'Solicitante'),
            const SizedBox(height: ManoSpacing.md),
            ManoAddressPill(
              address: 'Calle 93 #15-20, Bogotá',
              onTap: () => _showStub(context),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoSearchPill(onTap: () => _showStub(context)),
            const SizedBox(height: ManoSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Explora por categoría', style: textTheme.titleMedium),
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
                        priceLabel: _copLabel(listing.priceFromCents),
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
