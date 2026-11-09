import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';
import '../gateway/offer_json.dart';
import '../gateway/service_lookup.dart';

/// The `Job` selection every adapter asks for.
const jobFields =
    'id client { id } worker { id } offer { $offerFields } '
    'appointment { start end } status pricing { rateType amount } '
    'finalAmount { amount } createdAt';

/// Maps a gateway `Job`; [service] supplies its title.
Job jobFromJson(Map<String, dynamic> json, JobService? service) {
  final appointment = json['appointment'] as Map<String, dynamic>?;
  final pricing = json['pricing'] as Map<String, dynamic>;
  final finalAmount = json['finalAmount'] as Map<String, dynamic>?;
  return Job(
    id: json['id'] as String,
    offerId: (json['offer'] as Map<String, dynamic>)['id'] as String,
    serviceTitle: service?.title ?? '',
    client: partyFromId(_idOf(json['client'])),
    provider: partyFromId(_idOf(json['worker'])),
    rateType: pricing['rateType'] == 'HOURLY'
        ? RateType.hourly
        : RateType.fixed,
    amountCop: (pricing['amount'] as num).round(),
    // A job without an appointment is pinned to when it was created.
    start: dateTimeFromJson(appointment?['start'] ?? json['createdAt']),
    end: appointment == null ? null : dateTimeFromJson(appointment['end']),
    status: switch (json['status']) {
      'IN_PROGRESS' => JobStatus.inProgress,
      'FINISHED' => JobStatus.finished,
      'CANCELLED' => JobStatus.cancelled,
      _ => JobStatus.scheduled,
    },
    finalAmountCop: (finalAmount?['amount'] as num?)?.round(),
  );
}

/// Maps a gateway `Job`, looking its service up through [services].
Future<Job> enrichedJob(
  Map<String, dynamic> json,
  ServiceLookup services,
) async => jobFromJson(json, await services(offeredServiceIdOf(json)));

/// The gateway spelling of a job status.
String jobStatusToJson(JobStatus status) => switch (status) {
  JobStatus.scheduled => 'SCHEDULED',
  JobStatus.inProgress => 'IN_PROGRESS',
  JobStatus.finished => 'FINISHED',
  JobStatus.cancelled => 'CANCELLED',
};

String _idOf(Object? profile) =>
    (profile as Map<String, dynamic>)['id'] as String;
