import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Job payment domain -> Spanish (Colombia) copy for the checkout.

String payLabel(int amountCop) => 'Pagar ${ManoFormat.cop(amountCop)}';

/// The one breakdown line: the fixed price, or rate × hours.
String priceLine(Job job) => switch ((job.rateType, job.actualHours)) {
  (RateType.fixed, _) => 'Precio fijo',
  (RateType.hourly, final double hours) =>
    '${ManoFormat.cop(job.amountCop)} × ${_hours(hours)} h',
  (RateType.hourly, _) => 'Servicio por horas',
};

String _hours(double hours) => hours == hours.roundToDouble()
    ? hours.toInt().toString()
    : hours.toString().replaceAll('.', ',');

String? checkoutPhoneError(JobPaymentDraft draft) =>
    draft.phone.trim().isNotEmpty &&
        draft.problems.contains(JobPaymentProblem.invalidPhone)
    ? 'Un celular de 10 dígitos que empiece por 3.'
    : null;

String? checkoutLegalIdError(JobPaymentDraft draft) =>
    draft.legalId.trim().isNotEmpty &&
        draft.problems.contains(JobPaymentProblem.invalidLegalId)
    ? 'Revisa el número de documento.'
    : null;

String? checkoutEmailError(JobPaymentDraft draft) =>
    draft.payerEmail.trim().isNotEmpty &&
        draft.problems.contains(JobPaymentProblem.invalidPayerEmail)
    ? 'Revisa el correo.'
    : null;

/// Why a payment failed, without the backend's wording.
String checkoutFailureMessage(DataFailure failure) => switch (failure) {
  DataRejected() => 'El pago fue rechazado. No te cobramos nada.',
  _ => failure.message,
};
