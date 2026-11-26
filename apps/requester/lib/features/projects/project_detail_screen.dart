import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/load_error.dart';
import 'account_gate.dart';
import 'project_labels.dart';
import 'project_quotes_section.dart';
import 'project_sheets.dart';
import 'project_status_strip.dart';

const _accountNeeded = 'Inicia sesión para decidir sobre las cotizaciones.';

/// One of the requester's projects, with its quotes to compare and decide on.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(myProjectsProvider);
    final project = projects.value?.where((p) => p.id == projectId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (project != null && project.canCancel)
            IconButton(
              tooltip: 'Más opciones',
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _cancel(context, ref, project),
            ),
        ],
      ),
      body: switch (projects) {
        AsyncData() when project != null => _Body(
          project: project,
          onSelect: (q) => _select(context, ref, q),
          onDiscard: (q) => _discard(context, ref, q),
        ),
        AsyncData() => ManoEmptyState(
          icon: Icons.search_off,
          message: 'No encontramos este proyecto.',
          ctaLabel: 'Volver a Actividad',
          onCta: () => context.go('/projects'),
        ),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar este proyecto.',
          onRetry: () => ref.invalidate(myProjectsProvider),
        ),
        _ => const ManoSkeletonList(),
      },
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref, Quote quote) async {
    if (!requireAccount(context, ref, _accountNeeded)) return;
    final confirmed = await confirmSelectQuote(
      context,
      name: quote.workerName,
      amount: ManoFormat.cop(quote.amountCop),
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(projectActionsProvider.notifier)
        .selectQuote(quote.id);
    if (!context.mounted) return;
    _announce(context, result, 'Elegiste a ${quote.workerName}.');
  }

  Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    Quote quote,
  ) async {
    if (!requireAccount(context, ref, _accountNeeded)) return;
    final result = await ref
        .read(projectActionsProvider.notifier)
        .discardQuote(quote.id);
    if (!context.mounted) return;
    _announce(context, result, 'Descartaste la cotización.');
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    if (!await showProjectOptions(context) || !context.mounted) return;
    if (!requireAccount(
      context,
      ref,
      'Inicia sesión para cancelar el proyecto.',
    )) {
      return;
    }
    if (!await confirmCancelProject(context) || !context.mounted) return;
    final result = await ref
        .read(projectActionsProvider.notifier)
        .cancel(project.id);
    if (!context.mounted) return;
    _announce(context, result, 'Cancelaste el proyecto.');
  }

  void _announce(
    BuildContext context,
    Result<Object, DataFailure> result,
    String success,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            Ok() => success,
            Err(:final failure) => failure.message,
          }),
        ),
      );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.project,
    required this.onSelect,
    required this.onDiscard,
  });

  final Project project;
  final ValueChanged<Quote> onSelect;
  final ValueChanged<Quote> onDiscard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ManoSpacing.lg,
        0,
        ManoSpacing.lg,
        ManoSpacing.xl,
      ),
      children: [
        ProjectStatusStrip(status: project.status),
        const SizedBox(height: ManoSpacing.md),
        Text(project.title, style: textTheme.headlineSmall),
        const SizedBox(height: ManoSpacing.xs),
        Text(
          '${ServiceCategories.labelOf(project.category)} · Publicado '
          '${ManoFormat.ago(project.createdAt, DateTime.now())}',
          style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
        ),
        const SizedBox(height: ManoSpacing.md),
        Row(
          children: [
            Text(
              'Presupuesto',
              style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(width: ManoSpacing.sm),
            Flexible(
              child: Text(
                budgetLabel(project.budgetCop),
                style: textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(project.description, style: textTheme.bodyLarge),
        if (project.photoUrls.isNotEmpty) ...[
          const SizedBox(height: ManoSpacing.md),
          ManoPhotoGallery(urls: project.photoUrls, expandable: true),
        ],
        const SizedBox(height: ManoSpacing.lg),
        const Divider(color: ManoColors.stone),
        const SizedBox(height: ManoSpacing.md),
        ProjectQuotesSection(
          project: project,
          onSelect: onSelect,
          onDiscard: onDiscard,
        ),
      ],
    );
  }
}
