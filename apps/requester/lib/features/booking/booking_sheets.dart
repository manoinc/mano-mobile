import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// "$120.000" + "precio fijo", or "$45.000" + "/hora".
({String amount, String rate}) priceLabels(ServiceOffer offer) => (
  amount: ManoFormat.cop(offer.amountCop),
  rate: offer.rateType == RateType.hourly ? '/hora' : 'precio fijo',
);

const hourlyNote = 'El precio final depende de las horas trabajadas.';

/// Booking and requesting both need an account; true when one is signed in.
bool isSignedIn(WidgetRef ref) => ref.read(sessionProvider).value is SignedIn;

Future<void> showAccountNeededSheet(BuildContext context, WidgetRef ref) =>
    showManoSheet<void>(
      context: context,
      builder: (sheet) => ManoPromptSheet(
        title: 'Necesitas una cuenta',
        message:
            'Inicia sesión para agendar con este profesional. '
            'Solo toma un momento.',
        primaryLabel: 'Iniciar sesión',
        onClose: () => Navigator.pop(sheet),
        onPrimary: () {
          Navigator.pop(sheet);
          ref.read(onboardingFlowProvider.notifier).startSignIn();
        },
      ),
    );

/// True when the requester confirmed the summary.
Future<bool> showConfirmBookingSheet(
  BuildContext context, {
  required String serviceTitle,
  required DateTime start,
  required ServiceOffer offer,
}) async {
  final price = priceLabels(offer);
  final confirmed = await showManoSheet<bool>(
    context: context,
    builder: (sheet) => ManoPromptSheet(
      title: 'Confirma tu cita',
      message: 'Revisa los detalles antes de agendar.',
      primaryLabel: 'Confirmar',
      onClose: () => Navigator.pop(sheet),
      onPrimary: () => Navigator.pop(sheet, true),
      child: Column(
        children: [
          _SummaryRow(label: 'Servicio', value: serviceTitle),
          _SummaryRow(label: 'Fecha', value: ManoFormat.dateTime(start)),
          _SummaryRow(
            label: 'Precio',
            value: offer.rateType == RateType.hourly
                ? '${price.amount} ${price.rate}'
                : price.amount,
          ),
          if (offer.rateType == RateType.hourly)
            Padding(
              padding: const EdgeInsets.only(top: ManoSpacing.sm),
              child: Text(
                hourlyNote,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ManoColors.faint),
              ),
            ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
          ),
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
