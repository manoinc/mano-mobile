import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain -> Spanish (Colombia) copy for the Perfil screens.

const periodNames = ['Esta semana', 'Este mes'];

EarningsPeriod periodAt(int index) =>
    index == 1 ? EarningsPeriod.month : EarningsPeriod.week;

/// "4,9"
String ratingText(double rating) =>
    rating.toStringAsFixed(1).replaceAll('.', ',');

/// "96 %"
String percentText(int pct) => '$pct %';

const _weekInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// One label per bucket: weekday initials for a week, the start date for a month.
List<String> chartLabels(EarningsSummary summary) => [
  for (final bucket in summary.buckets)
    summary.period == EarningsPeriod.week
        ? _weekInitials[bucket.start.weekday - 1]
        : ManoFormat.dayMonth(bucket.start),
];

String payoutLine(Payout? payout) => payout == null
    ? 'Sin pagos pendientes'
    : 'Próximo pago: ${ManoFormat.cop(payout.amountCop)} · '
          '${ManoFormat.dayMonth(payout.date)}';

String yearsText(int years) =>
    years == 1 ? '1 año de experiencia' : '$years años de experiencia';

String reviewsCountText(int count) =>
    count == 1 ? '1 reseña' : '$count reseñas';

/// "4,9" and "32 reseñas"; a dash before the first review.
({String average, String count}) ratingLabels(RatingSummary summary) => (
  average: switch (summary.average) {
    final average? => ratingText(average),
    null => '–',
  },
  count: reviewsCountText(summary.count),
);

/// "3 colegas invitados · 2 verificados"
String referralCountText(int invited, int verified) =>
    '$invited ${invited == 1 ? 'colega invitado' : 'colegas invitados'} · '
    '$verified ${verified == 1 ? 'verificado' : 'verificados'}';

String referralOfferText(int coins) =>
    'Gana $coins Mano coins por cada colega verificado';

/// "luisa@mano.co · 3001112233", or null when neither is known.
String? contactText(String email, String phone) {
  final parts = [email.trim(), phone.trim()].where((p) => p.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' · ');
}

/// What the share sheet sends: an invitation to earn with Mano, the code and the link.
String referralMessage(String code, Uri link) =>
    'Te invito a Mano Profesionales: consigue clientes en tu zona y gana con '
    'tu oficio. Regístrate con mi código $code: $link';
