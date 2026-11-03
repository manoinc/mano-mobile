import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../provider_profile/provider_profile_route.dart';
import '../provider_profile/rating_labels.dart';

/// A project's quotes: the pick pinned, the rest sorted, discards folded away.
class ProjectQuotesSection extends ConsumerStatefulWidget {
  const ProjectQuotesSection({
    required this.project,
    required this.onSelect,
    required this.onDiscard,
    super.key,
  });

  final Project project;
  final ValueChanged<Quote> onSelect;
  final ValueChanged<Quote> onDiscard;

  @override
  ConsumerState<ProjectQuotesSection> createState() =>
      _ProjectQuotesSectionState();
}

class _ProjectQuotesSectionState extends ConsumerState<ProjectQuotesSection> {
  QuoteOrder _order = QuoteOrder.price;
  bool _showDiscarded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quotes = widget.project.quotes ?? const <Quote>[];
    final arranged = arrangeQuotes(quotes, _order);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cotizaciones (${quotes.length})',
                style: textTheme.titleMedium,
              ),
            ),
            if (quotes.length > 1)
              ManoTextAction(
                label: _order == QuoteOrder.price
                    ? 'Menor precio'
                    : 'Más recientes',
                onPressed: () => setState(
                  () => _order = _order == QuoteOrder.price
                      ? QuoteOrder.recency
                      : QuoteOrder.price,
                ),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.sm),
        if (quotes.isEmpty)
          Text(
            'Aún no hay cotizaciones.',
            style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
          ),
        if (arranged.selected case final picked?) _card(picked, now),
        for (final quote in arranged.active) _card(quote, now),
        if (arranged.discarded.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ManoTextAction(
              label: 'Descartadas (${arranged.discarded.length})',
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _showDiscarded = !_showDiscarded),
            ),
          ),
          if (_showDiscarded)
            for (final quote in arranged.discarded) _card(quote, now),
        ],
      ],
    );
  }

  Widget _card(Quote quote, DateTime now) {
    final project = widget.project;
    final selected = quote.status == QuoteStatus.selected;
    final photo = quote.worker.photoUrl;
    final rating = ref.watch(providerRatingProvider(quote.worker.id)).value;
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: ManoQuoteCard(
        key: Key('quote-${quote.id}'),
        avatar: photo.isEmpty
            ? ManoInitialsAvatar(
                initials: quote.workerInitials,
                tint: ManoInitialsAvatar.tintFor(quote.worker.id),
                size: 40,
              )
            : ManoAvatar(photoUrl: photo, size: 40),
        name: quote.workerName,
        ratingLabel: rating == null ? null : ratingBadgeText(rating),
        rated: rating?.hasRatings ?? false,
        onProviderTap: () => context.push(providerProfilePath(quote.worker.id)),
        amountLabel: ManoFormat.cop(quote.amountCop),
        ageLabel: ManoFormat.ago(quote.createdAt, now),
        message: quote.message,
        statusLabel: selected ? quote.statusLabel : null,
        statusTone: ManoStatusTone.success,
        selected: selected,
        onSelect: project.canSelect(quote)
            ? () => widget.onSelect(quote)
            : null,
        onDiscard: project.canDiscard(quote)
            ? () => widget.onDiscard(quote)
            : null,
      ),
    );
  }
}
