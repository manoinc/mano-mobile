/// The window an earnings summary covers.
enum EarningsPeriod { week, month }

/// What was earned in one slice of the period (a day or a week).
final class EarningsBucket {
  const EarningsBucket({required this.start, required this.amountCop});

  final DateTime start;
  final int amountCop;
}

/// A paid job in the breakdown.
final class PaidJob {
  const PaidJob({
    required this.jobId,
    required this.title,
    required this.client,
    required this.paidAt,
    required this.amountCop,
  });

  final String jobId;
  final String title;
  final String client;
  final DateTime paidAt;
  final int amountCop;
}

/// The money on its way to the bank.
final class Payout {
  const Payout({required this.amountCop, required this.date});

  final int amountCop;
  final DateTime date;
}

/// A provider's earnings for one [EarningsPeriod].
final class EarningsSummary {
  const EarningsSummary({
    required this.period,
    required this.buckets,
    required this.recent,
    this.nextPayout,
  });

  final EarningsPeriod period;
  final List<EarningsBucket> buckets;

  /// Paid jobs in the period, newest first.
  final List<PaidJob> recent;

  /// Null when nothing is pending.
  final Payout? nextPayout;

  int get totalCop => buckets.fold(0, (sum, b) => sum + b.amountCop);
}
