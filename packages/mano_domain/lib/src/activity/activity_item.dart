import '../jobs/job.dart';
import '../projects/project.dart';
import '../requests/service_request.dart';

/// Actividad's filters: waiting on an answer, under way, over.
enum ActivityBucket { pending, active, history }

/// One row of the requester's Actividad, whatever its kind.
sealed class ActivityItem {
  const ActivityItem();

  /// Null when the item is not listed at all.
  ActivityBucket? get bucket;

  /// Lists run newest first by this.
  DateTime get sortedAt;
}

final class RequestActivity extends ActivityItem {
  const RequestActivity(this.request);

  final ServiceRequest request;

  @override
  ActivityBucket? get bucket => switch (request.status) {
    ServiceRequestStatus.pending => ActivityBucket.pending,
    // Accepting creates a job, which stands for the request from then on.
    ServiceRequestStatus.accepted => null,
    ServiceRequestStatus.rejected ||
    ServiceRequestStatus.cancelled => ActivityBucket.history,
  };

  @override
  DateTime get sortedAt => request.createdAt;
}

final class JobActivity extends ActivityItem {
  const JobActivity(this.job);

  final Job job;

  @override
  ActivityBucket get bucket => switch (job.status) {
    JobStatus.scheduled || JobStatus.inProgress => ActivityBucket.active,
    JobStatus.finished || JobStatus.cancelled => ActivityBucket.history,
  };

  // Jobs carry no creation date; the start is their only timestamp.
  @override
  DateTime get sortedAt => job.start;
}

final class ProjectActivity extends ActivityItem {
  const ProjectActivity(this.project);

  final Project project;

  @override
  ActivityBucket get bucket => switch (project.status) {
    ProjectStatus.open => ActivityBucket.pending,
    ProjectStatus.awarded => ActivityBucket.active,
    ProjectStatus.closed || ProjectStatus.cancelled => ActivityBucket.history,
  };

  @override
  DateTime get sortedAt => project.createdAt;
}

/// The items in [bucket], newest first; ties keep requests, jobs, projects in source order.
List<ActivityItem> activityIn(
  ActivityBucket bucket, {
  required List<ServiceRequest> requests,
  required List<Job> jobs,
  required List<Project> projects,
}) {
  final items = <ActivityItem>[
    for (final r in requests) RequestActivity(r),
    for (final j in jobs) JobActivity(j),
    for (final p in projects) ProjectActivity(p),
  ].where((i) => i.bucket == bucket).indexed.toList();
  // List.sort is not stable, so the index breaks ties.
  items.sort((a, b) {
    final byTime = b.$2.sortedAt.compareTo(a.$2.sortedAt);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });
  return [for (final (_, item) in items) item];
}
