import 'package:mano_session/mano_session.dart';

// Domain problems → Spanish for the Perfil forms; [field] reads like "tu celular".

String problemCopy(FieldProblem problem, {required String field}) =>
    switch (problem) {
      FieldProblem.empty => 'Escribe $field.',
      FieldProblem.tooShort => 'Escribe un poco más.',
      FieldProblem.tooLong => 'Es muy largo.',
      FieldProblem.invalidCharacters => 'Usa solo letras.',
      FieldProblem.malformed => 'Revisa $field.',
      FieldProblem.expired => 'Esta tarjeta está vencida.',
    };

/// The description has its own wording: it asks for the story, not a field.
String descriptionCopy(FieldProblem problem) => switch (problem) {
  FieldProblem.empty => 'Cuéntanos qué pasó.',
  _ => problemCopy(problem, field: 'tu mensaje'),
};

/// "Mastercard 8341", "Nequi 4567" or "PSE".
String paymentMethodTitle(PaymentMethod method) => switch (method.kind) {
  PaymentKind.pse => 'PSE',
  _ => '${method.label} ${method.last4}',
};

/// The grey line under a method: "Vence: 05/2033" for a card.
String paymentMethodDetail(PaymentMethod method) => switch (method) {
  PaymentMethod(kind: PaymentKind.card, expiry: (:final month, :final year)) =>
    'Vence: ${month.toString().padLeft(2, '0')}/$year',
  PaymentMethod(kind: PaymentKind.card) => 'Tarjeta',
  PaymentMethod(kind: PaymentKind.nequi) => 'Billetera Nequi',
  PaymentMethod(kind: PaymentKind.pse) => 'Débito desde tu banco',
};

/// What the snackbar says once a referral code saved a professional.
String savedProfessionalCopy(String name) => name.trim().isEmpty
    ? 'Guardamos a tu profesional.'
    : 'Guardamos a ${name.trim()} en tus profesionales.';

String referralFailureCopy(DataFailure failure) => switch (failure) {
  DataNotFound() => 'Ese código no existe. Revísalo e intenta de nuevo.',
  _ => 'No pudimos guardar el código. Intenta de nuevo.',
};

/// "ana@mano.co · 3001234567", or null when neither is known.
String? contactLine(ClientProfile profile) {
  final parts = [
    profile.email.trim(),
    profile.phone.trim(),
  ].where((p) => p.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' · ');
}
