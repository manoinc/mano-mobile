import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'purchase_labels.dart';
import 'wallet_labels.dart';

/// What happened after Pagar: the next step, the wait, or the outcome; one primary action.
class PurchaseStatusView extends StatelessWidget {
  const PurchaseStatusView({
    required this.flow,
    required this.onOpenBank,
    required this.onCheckAgain,
    required this.onRetry,
    required this.onDone,
    required this.onClose,
    super.key,
  });

  final CoinPurchaseFlow flow;
  final ValueChanged<String> onOpenBank;
  final VoidCallback onCheckAgain;
  final VoidCallback onRetry;
  final VoidCallback onDone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (status, primary) = _content();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status,
        const SizedBox(height: ManoSpacing.xl),
        ?primary,
        if (flow is! PurchaseCredited) ...[
          const SizedBox(height: ManoSpacing.sm),
          ManoQuietButton(label: 'Cerrar', onPressed: onClose),
        ],
      ],
    );
  }

  (ManoPaymentStatus, Widget?) _content() => switch (flow) {
    PurchaseWaiting(step: AwaitingApproval(:final coins)) => (
      ManoPaymentStatus(
        icon: Icons.phone_iphone,
        title: 'Aprueba el pago en Nequi',
        message:
            'Abre Nequi y acepta la notificación. Tus ${coinsLabel(coins)} '
            'llegan apenas se confirme.',
        waitingLabel: 'Esperando a Nequi…',
      ),
      null,
    ),
    PurchaseWaiting(step: BankRedirect(:final url)) => (
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
    PurchaseWaiting() => (
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
    PurchaseCredited(:final coins, :final balance) => (
      ManoPaymentStatus(
        icon: Icons.check_rounded,
        title: '¡Listo! +${coinsLabel(coins)}',
        message: 'Ya tienes $balance Mano coins.',
        tone: ManoPaymentTone.done,
      ),
      ManoPrimaryButton(label: 'Listo', onPressed: onDone),
    ),
    PurchaseTimedOut() => (
      const ManoPaymentStatus(
        icon: Icons.hourglass_top_rounded,
        title: 'Tu pago sigue en proceso',
        message:
            'Cuando se confirme, verás los coins en tu Billetera. No hace '
            'falta pagar de nuevo.',
      ),
      ManoPrimaryButton(label: 'Revisar de nuevo', onPressed: onCheckAgain),
    ),
    PurchaseFailed(:final failure) => (
      ManoPaymentStatus(
        icon: Icons.error_outline,
        title: 'No pudimos hacer la recarga',
        message: purchaseFailureMessage(failure),
        tone: ManoPaymentTone.failed,
      ),
      ManoPrimaryButton(label: 'Intentar de nuevo', onPressed: onRetry),
    ),
    PurchaseIdle() || PurchaseSubmitting() => (
      const ManoPaymentStatus(
        icon: Icons.hourglass_top_rounded,
        title: 'Enviando tu pago',
        message: 'Un momento.',
      ),
      null,
    ),
  };
}
