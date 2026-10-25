import 'package:mano_data/src/gateway/offer_json.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('offerFromJson maps rate type, status and a decimal amount', () {
    expect(
      offerFromJson({
        'id': 'o1',
        'jobServiceId': 's1',
        'offerantId': 'p1',
        'rateType': 'HOURLY',
        'amount': 45000.4,
        'zone': 'Chapinero',
        'status': 'DELETED',
      }),
      const ServiceOffer(
        id: 'o1',
        jobServiceId: 's1',
        offerantId: 'p1',
        rateType: RateType.hourly,
        amountCop: 45000,
        zone: 'Chapinero',
        status: OfferStatus.deleted,
      ),
    );
  });

  test('offerFields selects every field offerFromJson reads', () {
    for (final field in [
      'id',
      'jobServiceId',
      'offerantId',
      'rateType',
      'amount',
      'zone',
      'status',
    ]) {
      expect(offerFields.split(' '), contains(field));
    }
  });

  test('rateTypeToJson is the gateway enum', () {
    expect(rateTypeToJson(RateType.fixed), 'FIXED');
    expect(rateTypeToJson(RateType.hourly), 'HOURLY');
  });
}
