import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'offer_labels.dart';
import '../account/account_gate.dart';

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
                Icons.add_circle_outline,
                color: ManoColors.muted,
              ),
              title: Text('Nueva oferta', style: textTheme.bodyLarge),
              trailing: const Icon(
                Icons.chevron_right,
                color: ManoColors.faint,
              ),
              onTap: () => _open(context, ref, '/profile/services/new'),
            ),
            const Divider(color: ManoColors.stone, height: 1),
            const SizedBox(height: ManoSpacing.md),
            Expanded(
              child: ManoPullToRefresh(
                onRefresh: () => ref.refresh(myOffersProvider.future),
                child: switch (offers) {
                  AsyncData(:final value) when value.isEmpty => ManoEmptyState(
                    icon: Icons.handyman_outlined,
                    message: 'Aún no ofreces ningún servicio',
                    ctaLabel: 'Publicar mi primer servicio',
                    onCta: () => _open(context, ref, '/profile/services/new'),
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
      onTap: () => _open(context, ref, '/profile/services/offer/${offer.id}'),
    );
  }
}

// Offers are created and edited only with an account.
Future<void> _open(BuildContext context, WidgetRef ref, String location) =>
    requireAccount(
      context,
      ref,
      reason: AccountReason.offers,
      action: () => context.push(location),
    );
