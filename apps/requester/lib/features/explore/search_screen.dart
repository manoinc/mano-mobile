import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'category_icons.dart';
import 'category_photos.dart';

const _debounce = Duration(milliseconds: 300);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.category, super.key});

  final String? category;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  late ServiceQuery _query = ServiceQuery(category: widget.category);
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _pending?.cancel();
    _pending = Timer(_debounce, () {
      if (mounted) setState(() => _query = _query.copyWith(text: text));
    });
  }

  void _toggleCategory(String id) => setState(() {
    final next = _query.categoryFilter == id ? null : id;
    _query = _query.copyWith(category: () => next);
  });

  void _clear() {
    _pending?.cancel();
    _controller.clear();
    setState(() => _query = const ServiceQuery());
  }

  // Nothing typed and no category picked: browse the grid instead of searching.
  bool get _browsing =>
      _query.categoryFilter == null && _query.searchText == null;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: ManoSpacing.md),
          child: ManoSearchField(
            controller: _controller,
            autofocus: widget.category == null,
            hintText: '¿Con qué necesitas ayuda?',
            onChanged: _onTextChanged,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: ManoMotion.normal,
        switchInCurve: ManoMotion.entrance,
        child: _browsing
            ? _CategoryGrid(
                key: const ValueKey('grid'),
                categories: categories,
                onSelected: _toggleCategory,
              )
            : Column(
                key: const ValueKey('results'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ManoSpacing.md,
                    ),
                    child: ManoCategoryRail(
                      items: categoryRailItems(categories),
                      selectedId: _query.categoryFilter,
                      onSelected: _toggleCategory,
                    ),
                  ),
                  Expanded(child: _results()),
                ],
              ),
      ),
    );
  }

  Widget _results() {
    final results = ref.watch(serviceSearchProvider(_query));
    return AnimatedSwitcher(
      duration: ManoMotion.normal,
      switchInCurve: ManoMotion.entrance,
      child: results.when(
        skipLoadingOnReload: true,
        loading: () =>
            const Center(key: ValueKey('loading'), child: ManoLoader()),
        error: (_, _) => ManoEmptyState(
          key: const ValueKey('error'),
          icon: Icons.wifi_off_outlined,
          message: 'No pudimos cargar los servicios.',
          ctaLabel: 'Reintentar',
          onCta: () => ref.invalidate(serviceSearchProvider(_query)),
        ),
        data: (services) => services.isEmpty
            ? ManoEmptyState(
                key: const ValueKey('empty'),
                icon: Icons.search_off,
                message: 'No encontramos servicios con esa búsqueda. Prueba otras palabras o categorías.',
                ctaLabel: 'Limpiar búsqueda',
                onCta: _clear,
              )
            : ListView.separated(
                key: ValueKey(_query),
                padding: const EdgeInsets.all(ManoSpacing.md),
                itemCount: services.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: ManoColors.stone, height: 1),
                itemBuilder: (context, i) => _ResultTile(
                  title: services[i].title,
                  category: ServiceCategories.labelOf(services[i].category),
                  description: services[i].description,
                  onTap: () => context.push('/home/service/${services[i].id}'),
                ),
              ),
      ),
    );
  }
}

/// Two columns of category tiles, Taskrabbit-style.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onSelected,
    super.key,
  });

  final List<ServiceCategory> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // Taller rows when the user enlarges text, so three-line labels still fit.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.count(
      padding: const EdgeInsets.all(ManoSpacing.md),
      crossAxisCount: 2,
      crossAxisSpacing: ManoSpacing.md,
      mainAxisSpacing: ManoSpacing.sm,
      childAspectRatio: 2.2 / scale.clamp(1, 2),
      children: [
        for (final category in categories)
          ManoCategoryTile(
            image: categoryPhoto(category.id),
            label: category.label,
            onTap: () => onSelected(category.id),
          ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.category,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String category;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: textTheme.labelSmall?.copyWith(color: ManoColors.clay),
            ),
            const SizedBox(height: ManoSpacing.xs),
            Text(title, style: textTheme.titleMedium),
            if (description.isNotEmpty) ...[
              const SizedBox(height: ManoSpacing.xs),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
