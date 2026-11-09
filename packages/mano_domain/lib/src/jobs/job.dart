import '../catalog/service_offer.dart';
import '../shared/party.dart';

enum JobStatus { scheduled, inProgress, finished, cancelled }

/// Agreed work with a time slot; created by booking or accepting a request.
final class Job {
  const Job({
    required this.id,
    required this.offerId,
    required this.serviceTitle,
    required this.client,
    required this.provider,
    required this.rateType,
    required this.amountCop,
    required this.start,
    required this.status,
    this.end,
    this.actualHours,
    this.finalAmountCop,
  });

  final String id;
  final String offerId;
  final String serviceTitle;
  final Party client;
  final Party provider;
  final RateType rateType;

  /// The fixed price, or the hourly rate for hourly jobs.
  final int amountCop;
  final DateTime start;
  final DateTime? end;
  final JobStatus status;
  final double? actualHours;

  /// What the job came to, set once finished (gateway `finalAmount`).
  final int? finalAmountCop;

  /// What the requester pays for a finished job.
  int get payableCop =>
      finalAmountCop ??
      switch ((rateType, actualHours)) {
        (RateType.hourly, final double hours) => (amountCop * hours).round(),
        _ => amountCop,
      };

  bool get canStart => status == JobStatus.scheduled;

  bool get canFinish => status == JobStatus.inProgress;

  bool get canCancel =>
      status == JobStatus.scheduled || status == JobStatus.inProgress;

  bool get canRebook =>
      status == JobStatus.finished || status == JobStatus.cancelled;

  bool get requiresHoursOnFinish => rateType == RateType.hourly;

  Job copyWith({JobStatus? status, double? actualHours}) => Job(
    id: id,
    offerId: offerId,
    serviceTitle: serviceTitle,
    client: client,
    provider: provider,
    rateType: rateType,
    amountCop: amountCop,
    start: start,
    end: end,
    status: status ?? this.status,
    actualHours: actualHours ?? this.actualHours,
    finalAmountCop: finalAmountCop,
  );

  @override
  bool operator ==(Object other) =>
      other is Job &&
      other.id == id &&
      other.offerId == offerId &&
      other.serviceTitle == serviceTitle &&
      other.client == client &&
      other.provider == provider &&
      other.rateType == rateType &&
      other.amountCop == amountCop &&
      other.start == start &&
      other.end == end &&
      other.status == status &&
      other.actualHours == actualHours &&
      other.finalAmountCop == finalAmountCop;

  @override
  int get hashCode => Object.hash(
    id,
    offerId,
    serviceTitle,
    client,
    provider,
    rateType,
    amountCop,
    start,
    end,
    status,
    actualHours,
    finalAmountCop,
  );

  @override
  String toString() => 'Job($id, $status)';
}
