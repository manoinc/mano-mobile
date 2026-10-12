import 'earnings.dart';

/// What the signed-in provider has earned.
abstract interface class EarningsRepository {
  Future<EarningsSummary> summary(EarningsPeriod period);
}
