import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'activity_labels.dart';
import 'load_error.dart';
import 'request_sheet.dart';

enum _Filter {
  requests(
    'Solicitudes',
    'No tienes solicitudes pendientes.',
    requestStatuses: [ServiceRequestStatus.pending],
  ),
  scheduled(
    'Programados',
    'No tienes trabajos programados.',
    jobStatus: JobStatus.scheduled,
  ),
  inProgress(
    'En curso',
    'Ningún trabajo está en curso ahora.',
    jobStatus: JobStatus.inProgress,
  ),
  finished(
    'Finalizados',
    'Aún no has terminado ningún trabajo.',
    jobStatus: JobStatus.finished,
  ),
  cancelled(
    'Cancelados',
    'No tienes nada cancelado.',
    jobStatus: JobStatus.cancelled,
    requestStatuses: [
      ServiceRequestStatus.rejected,
      ServiceRequestStatus.cancelled,
    ],
  );

  const _Filter(
    this.label,
    this.emptyMessage, {
    this.jobStatus,
    this.requestStatuses = const [],
  });

  final String label;
  final String emptyMessage;
  final JobStatus? jobStatus;
  final List<ServiceRequestStatus> requestStatuses;
}

/// The requester's requests and jobs, one status filter at a time; Actividad's Servicios segment.
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  _Filter _filter = _Filter.requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManoProjectFilterTabs(
          labels: [for (final f in _Filter.values) f.label],
          selectedIndex: _filter.index,
          onSelected: (i) => setState(() => _filter = _Filter.values[i]),
        ),
        const SizedBox(height: ManoSpacing.md),
        Expanded(
          child: ManoPullToRefresh(
            onRefresh: () => Future.wait([
              ref.refresh(myServiceRequestsProvider.future),
              ref.refresh(myJobsProvider.future),
            ]),
            child: _ActivityList(filter: _filter),
          ),
        ),
      ],
    );
  }
}

class _ActivityList extends ConsumerWidget {
  const _ActivityList({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobStatus = filter.jobStatus;
    final jobs = jobStatus == null
        ? const AsyncData(<Job>[])
        : ref.watch(jobsByStatusProvider(jobStatus));
    final requests = [
      for (final status in filter.requestStatuses)
        ref.watch(requestsByStatusProvider(status)),
    ];
    final all = <AsyncValue<List<Object>>>[jobs, ...requests];

    if (all.any((a) => a.hasError)) {
      return ActivityLoadError(
        message: 'No pudimos cargar tu actividad.',
        onRetry: () => ref
          ..invalidate(myJobsProvider)
          ..invalidate(myServiceRequestsProvider),
      );
    }
    if (all.any((a) => !a.hasValue)) {
      return const Center(child: ManoLoader());
    }

    final jobItems = jobs.requireValue;
    final requestItems = [for (final r in requests) ...r.requireValue];
    if (jobItems.isEmpty && requestItems.isEmpty) {
      return ManoEmptyState(
        icon: Icons.event_note_outlined,
        message: filter.emptyMessage,
        ctaLabel: 'Explorar servicios',
        onCta: () => context.go('/home'),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: ManoSpacing.lg),
      children: [
        for (final job in jobItems) _jobCard(context, job),
        for (final request in requestItems) _requestCard(context, ref, request),
      ],
    );
  }

  Widget _jobCard(BuildContext context, Job job) {
    final (label, tone) = jobBadge(job.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: ManoProjectCard(
        key: Key('activity-job-${job.id}'),
        title: job.serviceTitle,
        professionalName: job.providerName,
        professionalPhotoUrl: job.provider.photoUrl,
        statusLabel: label,
        statusTone: tone,
        scheduledLabel: ManoFormat.dateTime(job.start),
        priceLabel: shortPrice(job.amountCop, job.rateType),
        onTap: () => context.push('/projects/job/${job.id}'),
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) {
    final (label, tone) = requestBadge(request.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: ManoProjectCard(
        key: Key('activity-request-${request.id}'),
        title: request.serviceTitle,
        professionalName: request.providerName,
        professionalPhotoUrl: request.provider.photoUrl,
        statusLabel: label,
        statusTone: tone,
        scheduledLabel: ManoFormat.dateTime(
          request.proposedStart ?? request.createdAt,
        ),
        priceLabel: shortPrice(request.offer.amountCop, request.offer.rateType),
        onTap: () => _openRequest(context, ref, request),
      ),
    );
  }

  Future<void> _openRequest(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) async {
    final cancel = await showRequestSheet(context, request);
    if (cancel != true || !context.mounted) return;
    final result = await ref
        .read(activityActionsProvider.notifier)
        .cancelRequest(request.id);
    if (!context.mounted) return;
    final message = switch (result) {
      Ok() => 'Cancelamos tu solicitud.',
      Err(:final failure) => failure.message,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
