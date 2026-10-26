import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'lead_labels.dart';
import 'load_error.dart';

/// Inicio's Proyectos segment: open projects to quote on, by category.
class OpenProjectsSection extends ConsumerStatefulWidget {
  const OpenProjectsSection({super.key});

  @override
  ConsumerState<OpenProjectsSection> createState() =>
      _OpenProjectsSectionState();
}

class _OpenProjectsSectionState extends ConsumerState<OpenProjectsSection> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(providerCategoriesProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (categories.isNotEmpty) ...[
          ManoProjectFilterTabs(
            labels: [
              'Todas',
              for (final c in categories) ServiceCategories.labelOf(c),
            ],
            selectedIndex: _category == null
                ? 0
                : categories.indexOf(_category!) + 1,
            onSelected: (i) =>
                setState(() => _category = i == 0 ? null : categories[i - 1]),
          ),
          const SizedBox(height: ManoSpacing.md),
        ],
        _list(),
      ],
    );
  }

  Widget _list() {
    final projects = ref.watch(openProjectsProvider(_category));
    final now = DateTime.now();
    return switch (projects) {
      AsyncData(value: final items) when items.isEmpty => ManoEmptyState(
        icon: Icons.assignment_outlined,
        message: _category == null
            ? 'No hay proyectos abiertos por ahora.'
            : 'No hay proyectos abiertos en esta categoría.',
        ctaLabel: 'Ver mis servicios',
        onCta: () => context.go('/profile/services'),
      ),
      AsyncData(value: final items) => Column(
        children: [
          for (final project in items)
            Padding(
              padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
              child: ManoLeadCard(
                key: Key('lead-card-${project.id}'),
                title: project.title,
                categoryLabel: ServiceCategories.labelOf(project.category),
                ageLabel: ManoFormat.ago(project.createdAt, now),
                budgetLabel: leadBudgetLabel(project.budgetCop),
                costLabel: quoteCostLabel,
                onTap: () => context.push('/home/project/${project.id}'),
              ),
            ),
        ],
      ),
      AsyncError() => ProjectsLoadError(
        message: 'No pudimos cargar los proyectos.',
        onRetry: () => ref.invalidate(openProjectsProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
