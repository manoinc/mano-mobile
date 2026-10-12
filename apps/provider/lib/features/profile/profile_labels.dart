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

String referralProgressText(ReferralProgram program) =>
    '${program.invited} de ${program.goal} invitados';

String referralMessage(String code) =>
    'Únete a Mano Profesionales y consigue trabajos en tu zona. '
    'Usa mi código $code al registrarte.';
