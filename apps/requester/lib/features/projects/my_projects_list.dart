import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/load_error.dart';
import 'project_labels.dart';
import 'start_publishing.dart';

/// Actividad's Proyectos segment: the requester's projects, newest first.
class MyProjectsList extends ConsumerWidget {
  const MyProjectsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(myProjectsProvider);
    final now = DateTime.now();

    return ManoPullToRefresh(
      onRefresh: () => ref.refresh(myProjectsProvider.future),
      child: switch (projects) {
        AsyncData(value: final items) when items.isEmpty => ManoEmptyState(
          icon: Icons.assignment_outlined,
          message: 'Aún no has publicado proyectos.',
          ctaLabel: 'Publicar proyecto',
          onCta: () => startPublishing(context, ref),
        ),
        AsyncData(value: final items) => Stack(
          children: [
            ListView(
              // Room for the pill floating over the end of the list.
              padding: const EdgeInsets.only(bottom: ManoSpacing.xl * 3),
              children: [
                for (final project in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
                    child: _card(context, project, now),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: ManoSpacing.md,
              child: Center(
                child: _PublishPill(onTap: () => startPublishing(context, ref)),
              ),
            ),
          ],
        ),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar tus proyectos.',
          onRetry: () => ref.invalidate(myProjectsProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _card(BuildContext context, Project project, DateTime now) {
    final line = projectStatusLine(project);
    return ManoProjectSummaryCard(
      key: Key('project-card-${project.id}'),
      title: project.title,
      subtitle: projectSubtitle(project, now),
      statusLabel: line.label,
      statusTone: line.tone,
      trailingLabel: line.trailing,
      onTap: () => context.push('/projects/project/${project.id}'),
    );
  }
}

/// The floating flame pill, Angi-style; the segment's one primary action.
class _PublishPill extends StatelessWidget {
  const _PublishPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add),
      label: const Text('Publicar proyecto'),
      style: FilledButton.styleFrom(
        backgroundColor: ManoColors.flame,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.lg,
          vertical: ManoSpacing.md,
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
