import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../agenda/agenda_labels.dart';
import 'home_segments.dart';

/// Inicio: who's next, then requests, open projects and the quotes sent.
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(providerProfileProvider);
    final name = resolveGreetingName(
      ref.watch(currentUserProvider),
      profile.value,
      onboardingName: ref.watch(providerFirstNameProvider),
    );
    final next = ref.watch(upcomingJobsProvider).value?.firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: ManoPullToRefresh(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.all(ManoSpacing.md),
            children: [
              if (name != null)
                ManoGreetingHeader(
                  name: name,
                  photoUrl: greetingPhoto(profile.value, name: name),
                )
              else if (profile.isLoading)
                const SizedBox(height: ManoSpacing.xl)
              else
                Text(
                  'Inicio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              const SizedBox(height: ManoSpacing.lg),
              if (next != null) ...[
                Text(
                  'Próximo trabajo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ManoSpacing.md),
                _NextJobCard(job: next),
                const SizedBox(height: ManoSpacing.lg),
              ],
              const HomeSegments(),
              const SizedBox(height: ManoSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // Every segment's read, so whichever is showing comes back fresh.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(openProjectsProvider);
    await Future.wait([
      ref.refresh(myServiceRequestsProvider.future),
      ref.refresh(myJobsProvider.future),
      ref.refresh(myQuotesProvider.future),
    ]);
  }
}

class _NextJobCard extends StatelessWidget {
  const _NextJobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = jobBadge(job.status);
    return ManoProjectCard(
      key: const Key('home-next-job'),
      title: job.serviceTitle,
      professionalName: job.clientName,
      professionalPhotoUrl: job.client.photoUrl,
      statusLabel: label,
      statusTone: tone,
      scheduledLabel: ManoFormat.dateTime(job.start),
      priceLabel: shortPrice(job.amountCop, job.rateType),
      onTap: () => context.push('/agenda/job/${job.id}'),
    );
  }
}
