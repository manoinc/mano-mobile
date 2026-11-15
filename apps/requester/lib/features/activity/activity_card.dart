import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../projects/project_labels.dart';
import 'activity_labels.dart';
import 'request_sheet.dart';

/// One Actividad row, drawn with the card its kind already has.
class ActivityCard extends ConsumerWidget {
  const ActivityCard({required this.item, required this.now, super.key});

  final ActivityItem item;

  /// For the project cards' "hace 5h".
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (item) {
    JobActivity(:final job) => _jobCard(context, job),
    RequestActivity(:final request) => _requestCard(context, ref, request),
    ProjectActivity(:final project) => _projectCard(context, project),
  };

  Widget _jobCard(BuildContext context, Job job) {
    final (label, tone) = jobBadge(job.status);
    return ManoProjectCard(
      key: Key('activity-job-${job.id}'),
      title: job.serviceTitle,
      professionalName: job.providerName,
      professionalPhotoUrl: job.provider.photoUrl,
      statusLabel: label,
      statusTone: tone,
      scheduledLabel: ManoFormat.dateTime(job.start),
      priceLabel: shortPrice(job.amountCop, job.rateType),
      onTap: () => context.push('/projects/job/${job.id}'),
    );
  }

  Widget _requestCard(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) {
    final (label, tone) = requestBadge(request.status);
    return ManoProjectCard(
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
    );
  }

  Widget _projectCard(BuildContext context, Project project) {
    final line = projectStatusLine(project);
    return ManoProjectSummaryCard(
      key: Key('project-card-${project.id}'),
      title: project.title,
      subtitle: projectSubtitle(project, now),
      statusLabel: line.label,
      statusTone: line.tone,
      trailingLabel: line.trailing,
      onTap: () => context.push('/projects/project/${project.id}'),
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
