import '../result.dart';
import '../shared/data_failure.dart';
import 'service_offer.dart';

/// A provider managing their own offers.
abstract interface class OfferManagement {
  Future<List<ServiceOffer>> myOffers();

  Future<Result<ServiceOffer, DataFailure>> create({
    required String jobServiceId,
    required RateType rateType,
    required int amountCop,
    required String zone,
  });

  Future<Result<ServiceOffer, DataFailure>> update(
    String offerId, {
    RateType? rateType,
    int? amountCop,
    String? zone,
  });

  Future<Result<ServiceOffer, DataFailure>> pause(String offerId);

  Future<Result<ServiceOffer, DataFailure>> resume(String offerId);

  Future<Result<ServiceOffer, DataFailure>> delete(String offerId);
}
