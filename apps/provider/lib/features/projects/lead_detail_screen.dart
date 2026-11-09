import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';
import '../identity/verification_gate.dart';
import 'client_contact_section.dart';
import 'lead_labels.dart';
import 'lead_purchase_sheet.dart';
import 'load_error.dart';
import 'quote_sheet.dart';

/// A project and the provider's one quote on it; once awarded, read from the quote (docs/modules/PROV-07-projects.md).
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
    final quotes = ref.watch(myQuotesProvider);
    final mine = quotes.value
        ?.where((q) => q.projectId == widget.projectId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(),
      body: switch (board) {
        AsyncData() when project != null => _Body(project: project),
        // Awarded projects leave the open board; the quote still names them.
        AsyncData() when mine != null => _QuoteBody(quote: mine),
        AsyncData() when quotes.isLoading => const Center(
          child: CircularProgressIndicator(),
        ),
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
          ? _buyBar(mine)
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

  Widget? _buyBar(Quote? quote) => quote == null || !canBuyLead(quote)
      ? null
      : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: ManoPrimaryButton(
              label: 'Comprar contacto',
              onPressed: () => offerLeadPurchase(context, ref, quote),
            ),
          ),
        );

  Future<void> _quote(Project project) => requireVerified(
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

class _QuoteBody extends StatelessWidget {
  const _QuoteBody({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final contact = quote.clientContact;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ManoSpacing.lg,
        0,
        ManoSpacing.lg,
        ManoSpacing.xl,
      ),
      children: [
        Text(quote.projectTitle, style: textTheme.headlineSmall),
        const SizedBox(height: ManoSpacing.xs),
        Text(
          awardedQuoteLine(quote),
          style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
        ),
        if (contact != null && !contact.isEmpty) ...[
          const SizedBox(height: ManoSpacing.lg),
          ClientContactSection(contact: contact),
        ],
      ],
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
        if (project.photoUrls.isNotEmpty) ...[
          const SizedBox(height: ManoSpacing.md),
          ManoPhotoGallery(urls: project.photoUrls, expandable: true),
        ],
      ],
    );
  }
}
