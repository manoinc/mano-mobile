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

/// "Visa •••• 4242", "Nequi •••• 4567" or "PSE".
String paymentMethodTitle(PaymentMethod method) => switch (method.kind) {
  PaymentKind.pse => 'PSE',
  _ => '${method.label} •••• ${method.last4}',
};
