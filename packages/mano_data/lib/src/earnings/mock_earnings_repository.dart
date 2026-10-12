import 'package:mano_domain/mano_domain.dart';

/// In-memory [EarningsRepository]: a believable week and month, relative to now.
final class MockEarningsRepository implements EarningsRepository {
  MockEarningsRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const _daily = [0, 180000, 90000, 240000, 0, 135000, 120000];
  static const _weekly = [610000, 745000, 530000, 765000];

  @override
  Future<EarningsSummary> summary(EarningsPeriod period) async {
    final today = _today();
    final buckets = switch (period) {
      EarningsPeriod.week => [
        for (var i = 0; i < _daily.length; i++)
          EarningsBucket(
            start: today.subtract(Duration(days: _daily.length - 1 - i)),
            amountCop: _daily[i],
          ),
      ],
      EarningsPeriod.month => [
        for (var i = 0; i < _weekly.length; i++)
          EarningsBucket(
            start: today.subtract(Duration(days: 7 * (_weekly.length - 1 - i))),
            amountCop: _weekly[i],
          ),
      ],
    };
    final cutoff = switch (period) {
      EarningsPeriod.week => today.subtract(const Duration(days: 6)),
      EarningsPeriod.month => today.subtract(const Duration(days: 27)),
    };
    final jobs = _paidJobs(today);
    return EarningsSummary(
      period: period,
      buckets: buckets,
      recent: [
        for (final job in jobs)
          if (!job.paidAt.isBefore(cutoff)) job,
      ],
      nextPayout: Payout(
        amountCop: 375000,
        date: today.add(const Duration(days: 3)),
      ),
    );
  }

  DateTime _today() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  List<PaidJob> _paidJobs(DateTime today) {
    PaidJob job(String id, String title, String client, int ago, int amount) =>
        PaidJob(
          jobId: id,
          title: title,
          client: client,
          paidAt: today
              .subtract(Duration(days: ago))
              .add(const Duration(hours: 16)),
          amountCop: amount,
        );
    return [
      job('job-5', 'Limpieza profunda del hogar', 'Laura Pérez', 0, 120000),
      job('job-9', 'Reparación de fugas', 'Camilo Rojas', 1, 135000),
      job('job-8', 'Pintura de interiores', 'Marta Díaz', 2, 240000),
      job('job-7', 'Limpieza profunda del hogar', 'Julián Mora', 4, 90000),
      job('job-6', 'Reparación de fugas', 'Sara Gil', 5, 180000),
      job('job-4', 'Pintura de interiores', 'Laura Pérez', 12, 310000),
      job('job-3', 'Limpieza profunda del hogar', 'Diego Ruiz', 19, 235000),
    ];
  }
}
