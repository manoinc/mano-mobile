import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'checkout_labels.dart';

/// What happened after Pagar: the next step, the wait, or the outcome; one primary action.
class CheckoutStatusView extends StatelessWidget {
  const CheckoutStatusView({
    required this.flow,
    required this.providerName,
    required this.onOpenBank,
    required this.onCheckAgain,
    required this.onRetry,
    required this.onDone,
    required this.onClose,
    super.key,
  });

  final JobCheckoutFlow flow;
  final String providerName;
  final ValueChanged<String> onOpenBank;
  final VoidCallback onCheckAgain;
  final VoidCallback onRetry;
  final VoidCallback onDone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (status, primary) = _content();
    return Padding(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          status,
          const SizedBox(height: ManoSpacing.xl),
          ?primary,
          if (flow is! CheckoutPaid) ...[
            const SizedBox(height: ManoSpacing.sm),
            ManoQuietButton(label: 'Cerrar', onPressed: onClose),
          ],
        ],
      ),
    );
  }

  (ManoPaymentStatus, Widget?) _content() => switch (flow) {
    CheckoutWaiting(:final payment)
        when payment.status == JobPaymentStatus.awaitingApproval =>
      (
        ManoPaymentStatus(
          icon: Icons.phone_iphone,
          title: 'Aprueba el pago en Nequi',
          message:
              'Abre Nequi y acepta la notificación de '
              '${ManoFormat.cop(payment.amount)}.',
          waitingLabel: 'Esperando a Nequi…',
        ),
        null,
      ),
    CheckoutWaiting(payment: JobPayment(redirectUrl: final url?)) => (
      const ManoPaymentStatus(
        icon: Icons.account_balance_outlined,
        title: 'Termina el pago en tu banco',
        message:
            'Te llevamos a la página de tu banco por PSE. Cuando pagues, '
            'vuelve a Mano.',
        waitingLabel: 'Esperando confirmación del banco…',
      ),
      ManoPrimaryButton(
        label: 'Ir a mi banco',
        onPressed: () => onOpenBank(url),
      ),
    ),
    CheckoutWaiting() => (
      const ManoPaymentStatus(
        icon: Icons.hourglass_top_rounded,
        title: 'Estamos preparando tu pago',
        message:
            'Tu banco aún no nos da el enlace de pago. Lo pedimos de nuevo '
            'en unos segundos.',
        waitingLabel: 'Preparando…',
      ),
      null,
    ),
    CheckoutPaid(:final payment) => (
      ManoPaymentStatus(
        icon: Icons.check_rounded,
        title: '¡Pago listo!',
        message:
            'Le pagaste ${ManoFormat.cop(payment.amount)} a $providerName.',
        tone: ManoPaymentTone.done,
      ),
      ManoPrimaryButton(label: 'Listo', onPressed: onDone),
    ),
    CheckoutTimedOut() => (
      const ManoPaymentStatus(
        icon: Icons.hourglass_top_rounded,
        title: 'Tu pago sigue en proceso',
        message:
            'Cuando se confirme, el trabajo aparecerá como pagado. No hace '
            'falta pagar de nuevo.',
      ),
      ManoPrimaryButton(label: 'Revisar de nuevo', onPressed: onCheckAgain),
    ),
    CheckoutFailed(:final failure) => (
      ManoPaymentStatus(
        icon: Icons.error_outline,
        title: 'No pudimos cobrar el pago',
        message: checkoutFailureMessage(failure),
        tone: ManoPaymentTone.failed,
      ),
      ManoPrimaryButton(label: 'Intentar de nuevo', onPressed: onRetry),
    ),
    CheckoutIdle() || CheckoutSubmitting() => (
      const ManoPaymentStatus(
        icon: Icons.hourglass_top_rounded,
        title: 'Enviando tu pago',
        message: 'Un momento.',
      ),
      null,
    ),
  };
}
