import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'provider_about.dart';
import 'provider_profile_header.dart';
import 'provider_profile_skeleton.dart';
import 'provider_reviews_preview.dart';
import 'write_to_provider.dart';

/// REQ-07: a provider as requesters see them, from offers, quotes and chat.
class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(providerProfileViewProvider(providerId));

    return Scaffold(
      appBar: AppBar(),
      body: AnimatedSwitcher(
        duration: ManoMotion.normal,
        switchInCurve: ManoMotion.entrance,
        switchOutCurve: ManoMotion.exit,
        child: switch (view) {
          AsyncData(value: final loaded?) => _Loaded(view: loaded),
          AsyncData() => const ManoEmptyState(
            icon: Icons.person_search_outlined,
            message: 'No encontramos a este profesional',
          ),
          AsyncError() => ManoEmptyState(
            icon: Icons.cloud_off_outlined,
            message: 'No pudimos cargar el perfil',
            ctaLabel: 'Reintentar',
            onCta: () =>
                ref.invalidate(providerProfileViewProvider(providerId)),
          ),
          _ => const ProviderProfileSkeleton(),
        },
      ),
      bottomNavigationBar: switch (view) {
        AsyncData(value: final loaded?) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ManoSpacing.md,
              ManoSpacing.sm,
              ManoSpacing.md,
              ManoSpacing.md,
            ),
            child: WriteToProviderButton(providerId: loaded.profile.party.id),
          ),
        ),
        _ => null,
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.view});

  final ProviderProfileView view;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      ManoSpacing.lg,
      0,
      ManoSpacing.lg,
      ManoSpacing.xl,
    ),
    children: [
      ProviderProfileHeader(profile: view.profile, rating: view.rating),
      const SizedBox(height: ManoSpacing.lg),
      const Divider(),
      const SizedBox(height: ManoSpacing.lg),
      ProviderAbout(profile: view.profile),
      const SizedBox(height: ManoSpacing.xl),
      ProviderReviewsPreview(
        providerId: view.profile.party.id,
        rating: view.rating,
        reviews: view.reviews,
      ),
    ],
  );
}
