import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'lead_labels.dart';
import 'lead_purchase_sheet.dart';
import 'load_error.dart';

/// Inicio's Mis cotizaciones segment: the quotes sent, and how each went.
class MyQuotesSection extends ConsumerWidget {
  const MyQuotesSection({required this.onBrowse, super.key});

  /// Shows the open projects instead.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(leadPricesProvider).value;
    return switch (ref.watch(myQuotesProvider)) {
      AsyncData(value: final quotes) when quotes.isEmpty => ManoEmptyState(
        icon: Icons.request_quote_outlined,
        message: 'Aún no has enviado cotizaciones.',
        ctaLabel: 'Ver proyectos',
        onCta: onBrowse,
      ),
      AsyncData(value: final quotes) => Column(
        children: [
          for (final quote in quotes)
            Padding(
              padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
              child: ManoProjectSummaryCard(
                key: Key('my-quote-${quote.id}'),
                title: quote.projectTitle,
                subtitle: myQuoteSubtitle(quote, prices),
                statusLabel: quote.statusLabel,
                statusTone: quoteTone(quote),
                trailingLabel: quote.status == QuoteStatus.selected
                    ? ManoFormat.cop(quote.amountCop)
                    : null,
                onTap: () => canBuyLead(quote)
                    ? offerLeadPurchase(context, ref, quote)
                    : context.push('/home/project/${quote.projectId}'),
              ),
            ),
        ],
      ),
      AsyncError() => ProjectsLoadError(
        message: 'No pudimos cargar tus cotizaciones.',
        onRetry: () => ref.invalidate(myQuotesProvider),
      ),
      _ => const Center(child: ManoLoader()),
    };
  }
}
