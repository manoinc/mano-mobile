import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';
import 'lead_labels.dart';
import 'load_error.dart';
import 'quote_sheet.dart';

/// An open project, and the provider's one quote on it (docs/modules/PROV-07-projects.md).
class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(openProjectsProvider(null));
    final project = board.value
        ?.where((p) => p.id == widget.projectId)
        .firstOrNull;
    final mine = ref
        .watch(myQuotesProvider)
        .value
        ?.where((q) => q.projectId == widget.projectId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(),
      body: switch (board) {
        AsyncData() when project != null => _Body(project: project),
        AsyncData() => ManoEmptyState(
          icon: Icons.lock_clock_outlined,
          message: 'Este proyecto ya no recibe cotizaciones.',
          ctaLabel: 'Volver a Inicio',
          onCta: () => context.go('/home'),
        ),
        AsyncError() => ProjectsLoadError(
          message: 'No pudimos cargar este proyecto.',
          onRetry: () => ref.invalidate(openProjectsProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: project == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(ManoSpacing.md),
                child: mine != null
                    ? _Quoted(amountCop: mine.amountCop)
                    : project.acceptsQuotes
                    ? ManoPrimaryButton(
                        label: 'Cotizar gratis',
                        busy: _busy,
                        onPressed: () => _quote(project),
                      )
                    : null,
              ),
            ),
    );
  }

  Future<void> _quote(Project project) => requireAccount(
    context,
    ref,
    reason: AccountReason.projects,
    action: () => _submitQuote(project),
  );

  Future<void> _submitQuote(Project project) async {
    final quote = await showQuoteSheet(context);
    if (quote == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(leadActionsProvider.notifier)
        .submitQuote(
          project.id,
          amountCop: quote.amountCop,
          message: quote.message,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.failureOrNull case final failure? when failure.isAlreadyQuoted) {
      // Another device may have quoted; show what is on record.
      ref.invalidate(myQuotesProvider);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            Ok() => 'Cotización enviada',
            Err(:final failure) => quoteFailureMessage(failure),
          }),
        ),
      );
  }
}

class _Quoted extends StatelessWidget {
  const _Quoted({required this.amountCop});

  final int amountCop;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ManoColors.sand,
        borderRadius: BorderRadius.circular(ManoRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Text(
          'Ya cotizaste · ${ManoFormat.cop(amountCop)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final budget = project.budgetCop;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ManoSpacing.lg,
        0,
        ManoSpacing.lg,
        ManoSpacing.xl,
      ),
      children: [
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
              'Presupuesto del cliente',
              style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(width: ManoSpacing.sm),
            Text(
              budget == null ? 'Sin presupuesto' : ManoFormat.cop(budget),
              style: textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
        Text(project.description, style: textTheme.bodyLarge),
      ],
    );
  }
}
