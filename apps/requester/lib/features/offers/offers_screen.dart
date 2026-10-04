import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const _filterLabels = {
  OfferPricingFilter.all: 'Todas',
  OfferPricingFilter.fixed: 'Precio fijo',
  OfferPricingFilter.hourly: 'Por hora',
};

/// REQ-02: every active offer for one service, cheapest first.
class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({required this.serviceId, super.key});

  final String serviceId;

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  OfferPricingFilter _filter = OfferPricingFilter.all;

  void _retry() {
    ref.invalidate(jobServiceProvider(widget.serviceId));
    ref.invalidate(offersForServiceProvider(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(jobServiceProvider(widget.serviceId));
    final offers = ref.watch(offersForServiceProvider(widget.serviceId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ManoSpacing.md,
              0,
              ManoSpacing.md,
              ManoSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.value?.title ?? '',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: ManoSpacing.xs),
                Text(
                  'Ofertas disponibles',
                  style: textTheme.bodyMedium?.copyWith(
                    color: ManoColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (offers) {
              AsyncData(:final value) when value.isEmpty => ManoEmptyState(
                icon: Icons.storefront_outlined,
                message: 'Aún no hay ofertas para este servicio',
                ctaLabel: 'Volver',
                onCta: () => context.pop(),
              ),
              AsyncData(:final value) => _FilteredOffers(
                offers: value,
                filter: _filter,
                onFilter: (f) => setState(() => _filter = f),
              ),
              AsyncError() => ManoEmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'No pudimos cargar las ofertas',
                ctaLabel: 'Reintentar',
                onCta: _retry,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _FilteredOffers extends StatelessWidget {
  const _FilteredOffers({
    required this.offers,
    required this.filter,
    required this.onFilter,
  });

  final List<ServiceOffer> offers;
  final OfferPricingFilter filter;
  final ValueChanged<OfferPricingFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final visible = filter.apply(offers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.md),
          child: ManoProjectFilterTabs(
            labels: _filterLabels.values.toList(),
            selectedIndex: filter.index,
            onSelected: (i) => onFilter(OfferPricingFilter.values[i]),
          ),
        ),
        const SizedBox(height: ManoSpacing.md),
        Expanded(
          child: AnimatedSwitcher(
            duration: ManoMotion.normal,
            switchInCurve: ManoMotion.entrance,
            switchOutCurve: ManoMotion.exit,
            child: visible.isEmpty
                ? Center(
                    key: ValueKey('empty-$filter'),
                    child: Text(
                      'No hay ofertas con este tipo de precio',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: ManoColors.faint),
                    ),
                  )
                : ListView.separated(
                    key: ValueKey(filter),
                    padding: const EdgeInsets.fromLTRB(
                      ManoSpacing.md,
                      0,
                      ManoSpacing.md,
                      ManoSpacing.lg,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: ManoSpacing.sm),
                    itemBuilder: (context, i) => _OfferTile(offer: visible[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer});

  final ServiceOffer offer;

  @override
  Widget build(BuildContext context) {
    void book() => context.push('/home/book/${offer.id}');
    final hourly = offer.rateType == RateType.hourly;

    // The gateway returns only offerantId, so the provider stays anonymous.
    return ManoOfferCard(
      leading: const ManoInitialsAvatar(initials: 'P', size: 40),
      title: 'Profesional',
      subtitle: hourly ? 'Por hora' : 'Precio fijo',
      amountLabel: ManoFormat.cop(offer.amountCop),
      rateLabel: hourly ? '/hora' : 'precio fijo',
      zone: offer.hasZone ? 'Zona: ${offer.zone}' : 'Sin zona definida',
      trailing: ManoTextAction(label: 'Agendar', onPressed: book),
      onTap: book,
    );
  }
}
