import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'offer_labels.dart';

/// PROV-02: the provider's own offers, plus the way into availability.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(myOffersProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ManoSpacing.md,
                ManoSpacing.lg,
                ManoSpacing.md,
                ManoSpacing.xs,
              ),
              child: Text('Mis servicios', style: textTheme.headlineSmall),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ManoSpacing.md,
              ),
              leading: const Icon(
                Icons.event_available_outlined,
                color: ManoColors.muted,
              ),
              title: Text(
                'Disponibilidad y calendario',
                style: textTheme.bodyLarge,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: ManoColors.faint,
              ),
              onTap: () => context.push('/agenda/availability'),
            ),
            const Divider(color: ManoColors.stone, height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ManoSpacing.md,
              ),
              leading: const Icon(
                Icons.add_circle_outline,
                color: ManoColors.muted,
              ),
              title: Text('Nueva oferta', style: textTheme.bodyLarge),
              trailing: const Icon(
                Icons.chevron_right,
                color: ManoColors.faint,
              ),
              onTap: () => context.push('/profile/services/new'),
            ),
            const Divider(color: ManoColors.stone, height: 1),
            const SizedBox(height: ManoSpacing.md),
            Expanded(
              child: switch (offers) {
                AsyncData(:final value) when value.isEmpty => ManoEmptyState(
                  icon: Icons.handyman_outlined,
                  message: 'Aún no ofreces ningún servicio',
                  ctaLabel: 'Publicar mi primer servicio',
                  onCta: () => context.push('/profile/services/new'),
                ),
                AsyncData(:final value) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    ManoSpacing.md,
                    0,
                    ManoSpacing.md,
                    ManoSpacing.lg,
                  ),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: ManoSpacing.sm),
                  itemBuilder: (context, i) => _OfferTile(offer: value[i]),
                ),
                AsyncError() => ManoEmptyState(
                  icon: Icons.cloud_off_outlined,
                  message: 'No pudimos cargar tus servicios',
                  ctaLabel: 'Reintentar',
                  onCta: () => ref.invalidate(myOffersProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTile extends ConsumerWidget {
  const _OfferTile({required this.offer});

  final ServiceOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(jobServiceProvider(offer.jobServiceId)).value;
    final (label, tone) = offerBadge(offer.status);

    return ManoOfferCard(
      title: service?.title ?? 'Servicio',
      subtitle: pricingModel(offer.rateType),
      amountLabel: ManoFormat.cop(offer.amountCop),
      rateLabel: rateLabel(offer.rateType),
      zone: offer.hasZone ? 'Zona: ${offer.zone}' : 'Sin zona definida',
      status: ManoStatusChip(label: label, tone: tone),
      onTap: () => context.push('/profile/services/offer/${offer.id}'),
    );
  }
}
