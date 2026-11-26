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

const inviteCodeProblemCopy = 'Revisa el código, se ve así: RP-1a2b3c4d.';

/// Shown once after the profile is sent, when the colleague's code was not recorded.
String referralFailureCopy(ReferralRedemptionFailure failure) =>
    switch (failure) {
      ReferralRedemptionFailure.unknownCode =>
        'No encontramos el código de tu colega.',
      ReferralRedemptionFailure.ownCode =>
        'Ese código es el tuyo; no cuenta como invitación.',
      ReferralRedemptionFailure.alreadyRedeemed =>
        'Ya tienes registrado al colega que te invitó.',
      ReferralRedemptionFailure.notSaved =>
        'No pudimos registrar el código de tu colega.',
    };

String documentLabel(ProviderDocument document) => switch (document) {
  ProviderDocument.certificates => 'Certificados o soportes (opcional)',
};

// The copy is shared through mano_session; the tone is this app's choice.
ManoNoticeTone authFailureTone(AuthFailure failure) => switch (failure) {
  SignInCancelled() => ManoNoticeTone.info,
  SessionExpired() ||
  AuthUnavailable() ||
  TooManyAttempts() => ManoNoticeTone.warning,
  SignInRejected() ||
  WrongCredentials() ||
  EmailAlreadyRegistered() ||
  InvalidCode() ||
  CodeExpired() => ManoNoticeTone.error,
};

/// The intro slides: a headline and one line each.
const introSlides = [
  (
    title: 'Recibe solicitudes en tu zona',
    subtitle: 'Hogares cerca de ti piden ayuda y tú eliges cuáles tomar.',
  ),
  (
    title: 'Tú pones tu precio y tu agenda',
    subtitle: 'Haces tus ofertas y decides cuándo tienes disponibilidad.',
  ),
  (
    title: 'Cobra seguro con Mano',
    subtitle: 'Verificamos tu identidad y los pagos van por la app.',
  ),
];

const introSkipLabel = 'Saltar';
const introStartLabel = 'Empezar';
const introNextLabel = 'Siguiente';
const introDoneLabel = 'Comenzar';
