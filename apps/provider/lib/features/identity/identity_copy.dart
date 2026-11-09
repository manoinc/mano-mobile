import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const photoTips = [
  ManoTip('Limpia el lente de tu cámara', emphasis: 'Limpia el lente'),
  ManoTip(
    'Pon la cédula sobre una superficie plana y oscura',
    emphasis: 'superficie plana y oscura',
  ),
  ManoTip(
    'Evita reflejos y sombras para que los datos se lean',
    emphasis: 'los datos se lean',
  ),
  ManoTip('Que se vea completa, sin dedos encima', emphasis: 'completa'),
];

const commonMistakes = [
  ManoTip('La cédula lejos o fuera del marco', emphasis: 'fuera del marco'),
  ManoTip('Sombras o brillo sobre los datos', emphasis: 'Sombras o brillo'),
  ManoTip('El lente de la cámara sucio', emphasis: 'lente'),
];

/// What the camera guide asks for at each photo.
String captureInstruction(IdentityDocumentKind kind) => switch (kind) {
  IdentityDocumentKind.cedulaFront => 'Muestra el frente de tu cédula',
  IdentityDocumentKind.cedulaBack => 'Muestra el reverso de tu cédula',
  IdentityDocumentKind.selfie => 'Mira a la cámara',
};

String captureHint(IdentityDocumentKind kind) => switch (kind) {
  IdentityDocumentKind.cedulaFront || IdentityDocumentKind.cedulaBack =>
    'Colócala dentro del marco y toma la foto.',
  IdentityDocumentKind.selfie =>
    'Con buena luz, sin gafas ni gorra, para confirmar que eres tú.',
};

String documentName(IdentityDocumentKind kind) => switch (kind) {
  IdentityDocumentKind.cedulaFront => 'Frente de la cédula',
  IdentityDocumentKind.cedulaBack => 'Reverso de la cédula',
  IdentityDocumentKind.selfie => 'Selfie',
};
