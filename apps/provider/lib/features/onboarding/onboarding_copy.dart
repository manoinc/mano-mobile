import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

String displayNameProblemCopy(ProfileProblem problem) => switch (problem) {
  ProfileProblem.empty => 'Escribe tu nombre.',
  ProfileProblem.tooShort ||
  ProfileProblem.invalid => 'Tu nombre es muy corto.',
};

String phoneProblemCopy(ProfileProblem problem) => switch (problem) {
  ProfileProblem.empty => 'Escribe tu celular.',
  ProfileProblem.tooShort || ProfileProblem.invalid =>
    'Escribe un celular de 10 dígitos que empiece por 3.',
};

String workZoneProblemCopy(ProfileProblem problem) =>
    'Escribe tu zona de cobertura.';

const experienceProblemCopy = 'Escribe un número de años entre 0 y 60.';

const bioProblemCopy = 'Usa máximo 280 caracteres.';

String documentLabel(ProviderDocument document) => switch (document) {
  ProviderDocument.idFront => 'Documento de identidad (frente)',
  ProviderDocument.idBack => 'Documento de identidad (reverso)',
  ProviderDocument.certificates => 'Certificados o soportes (opcional)',
};

// Same copy and tones as the requester's sign-in, so both apps speak alike.
String authFailureCopy(AuthFailure failure) => switch (failure) {
  SignInCancelled() => 'Cancelaste el inicio de sesión.',
  SessionExpired() => 'Tu sesión venció. Vuelve a iniciar sesión.',
  AuthUnavailable() =>
    'No pudimos conectar con el servicio de inicio de sesión. '
        'Vuelve a intentarlo en un momento.',
  SignInRejected() => 'Correo o contraseña incorrectos.',
};

ManoNoticeTone authFailureTone(AuthFailure failure) => switch (failure) {
  SignInCancelled() => ManoNoticeTone.info,
  SessionExpired() || AuthUnavailable() => ManoNoticeTone.warning,
  SignInRejected() => ManoNoticeTone.error,
};
