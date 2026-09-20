import 'package:mano_session/mano_session.dart';

/// Turns a domain [FieldProblem] into something a person can act on.
///
/// The domain names problems in English for logs and tests; the Spanish lives
/// here, the same split `sign_in_screen.dart` uses for [AuthFailure]. Tuteo,
/// short, says what to do rather than what went wrong.
String nameProblemCopy(FieldProblem problem, {required String field}) =>
    switch (problem) {
      FieldProblem.empty => 'Escribe tu $field.',
      FieldProblem.tooShort => 'Tu $field es muy corto.',
      FieldProblem.tooLong => 'Tu $field es muy largo.',
      FieldProblem.invalidCharacters => 'Usa solo letras en tu $field.',
    };

String addressProblemCopy(FieldProblem problem) => switch (problem) {
  FieldProblem.empty => 'Escribe tu dirección.',
  FieldProblem.tooShort => 'Escribe la dirección completa.',
  FieldProblem.tooLong => 'Esa dirección es muy larga.',
  FieldProblem.invalidCharacters => 'Revisa tu dirección.',
};
