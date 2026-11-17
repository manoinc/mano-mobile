import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../projects/publish_project_pill.dart';
import '../projects/start_publishing.dart';
import 'activity_card.dart';
import 'load_error.dart';

const _emptyMessages = {
  ActivityBucket.pending: 'No tienes nada pendiente.',
  ActivityBucket.active: 'Nada está en curso ahora.',
  ActivityBucket.history: 'Aún no tienes historial.',
};

/// Actividad's one list: requests, jobs and projects in [bucket], newest first.
class ActivityList extends ConsumerWidget {
  const ActivityList({required this.bucket, super.key});

  final ActivityBucket bucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider(bucket));
    final now = DateTime.now();
    return Stack(
      children: [
        Positioned.fill(
          child: ManoPullToRefresh(
            onRefresh: () => Future.wait([
              ref.refresh(myServiceRequestsProvider.future),
              ref.refresh(myJobsProvider.future),
              ref.refresh(myProjectsProvider.future),
            ]),
            child: switch (activity) {
              _ when activity.hasError => ActivityLoadError(
                message: 'No pudimos cargar tu actividad.',
                onRetry: () => ref
                  ..invalidate(myServiceRequestsProvider)
                  ..invalidate(myJobsProvider)
                  ..invalidate(myProjectsProvider),
              ),
              _ when !activity.hasValue => const Center(child: ManoLoader()),
              _ when activity.requireValue.isEmpty => ManoEmptyState(
                icon: Icons.event_note_outlined,
                message: _emptyMessages[bucket]!,
              ),
              _ => ListView(
                // Room for the pill floating over the end of the list.
                padding: const EdgeInsets.only(bottom: ManoSpacing.xl * 3),
                children: [
                  for (final item in activity.requireValue)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
                      child: ActivityCard(item: item, now: now),
                    ),
                ],
              ),
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: ManoSpacing.md,
          child: Center(
            child: PublishProjectPill(
              onTap: () => startPublishing(context, ref),
            ),
          ),
        ),
      ],
    );
  }
}
