import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/profile/profile_labels.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('rating uses a decimal comma', () => expect(ratingText(4.9), '4,9'));

  test('a rating summary reads as average and count', () {
    final labels = ratingLabels(const RatingSummary(average: 4.86, count: 32));
    expect(labels.average, '4,9');
    expect(labels.count, '32 reseñas');
    expect(
      ratingLabels(const RatingSummary(average: 5, count: 1)).count,
      '1 reseña',
    );
    expect(ratingLabels(RatingSummary.none).average, '–');
  });

  test('payout line shows amount and date, or says none is pending', () {
    expect(
      payoutLine(Payout(amountCop: 375000, date: DateTime(2026, 10, 17))),
      'Próximo pago: \$375.000 · 17 oct',
    );
    expect(payoutLine(null), 'Sin pagos pendientes');
  });

  test('week labels are weekday initials; month labels are dates', () {
    final week = EarningsSummary(
      period: EarningsPeriod.week,
      buckets: [
        EarningsBucket(start: DateTime(2026, 10, 12), amountCop: 1),
        EarningsBucket(start: DateTime(2026, 10, 14), amountCop: 1),
      ],
      recent: const [],
    );
    expect(chartLabels(week), ['L', 'X']);
    final month = EarningsSummary(
      period: EarningsPeriod.month,
      buckets: [EarningsBucket(start: DateTime(2026, 10, 12), amountCop: 1)],
      recent: const [],
    );
    expect(chartLabels(month), ['12 oct']);
  });

  test('referral counts read invited, then verified', () {
    expect(referralCountText(2, 1), '2 colegas invitados · 1 verificado');
    expect(referralCountText(1, 0), '1 colega invitado · 0 verificados');
    expect(referralCountText(3, 2), '3 colegas invitados · 2 verificados');
  });

  test('the offer pays per verified colleague', () {
    expect(
      referralOfferText(10),
      'Gana 10 Mano coins por cada colega verificado',
    );
  });

  test('the share message carries the code and the link', () {
    final message = referralMessage(
      'RP-bb2cde6b',
      Uri.parse('https://manoapp.co/r/RP-bb2cde6b'),
    );
    expect(message, contains('RP-bb2cde6b'));
    expect(message, endsWith('https://manoapp.co/r/RP-bb2cde6b'));
  });
}
