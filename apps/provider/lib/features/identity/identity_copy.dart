import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const photoTips = [
  ManoTip('Limpia el lente de tu cámara', emphasis: 'Limpia el lente'),
  ManoTip(
    'Revisa que tu cédula no tenga manchas ni calcomanías',
    emphasis: 'no tenga manchas ni calcomanías',
  ),
  ManoTip(
    'Toma la foto sobre una superficie plana y opaca',
    emphasis: 'superficie plana y opaca',
  ),
  ManoTip(
    'Evita reflejos y sombras para que los datos se lean',
    emphasis: 'los datos se lean',
  ),
];

const commonMistakes = [
  ManoTip('La cédula lejos o fuera del marco', emphasis: 'fuera del marco'),
  ManoTip('Sombras o brillo sobre los datos', emphasis: 'Sombras o brillo'),
  ManoTip('El lente de la cámara sucio', emphasis: 'lente'),
];

/// The line over each photo's picture, and the fragment set in flame.
({String text, String? emphasis}) captureHeadline(IdentityDocumentKind kind) =>
    switch (kind) {
      IdentityDocumentKind.cedulaFront => (
        text: 'Toma la foto del frente de tu cédula',
        emphasis: 'foto del frente',
      ),
      IdentityDocumentKind.cedulaBack => (
        text: 'Voltea tu cédula para tomar una foto de la parte de atrás',
        emphasis: 'Voltea tu cédula',
      ),
      IdentityDocumentKind.selfie => (
        text: '¿Tomamos tu selfie?',
        emphasis: null,
      ),
    };

/// The line over the camera's guide, as Nu labels it.
String captureInstruction(IdentityDocumentKind kind) => switch (kind) {
  IdentityDocumentKind.cedulaFront => 'Muestra el frente de tu cédula',
  IdentityDocumentKind.cedulaBack => 'Muestra el reverso de tu cédula',
  IdentityDocumentKind.selfie => 'Mira a la cámara',
};

const cameraDenied =
    'Necesitamos acceso a tu cámara para tomar las fotos. Actívalo en los '
    'ajustes de tu teléfono.';

String documentName(IdentityDocumentKind kind) => switch (kind) {
  IdentityDocumentKind.cedulaFront => 'Frente de la cédula',
  IdentityDocumentKind.cedulaBack => 'Reverso de la cédula',
  IdentityDocumentKind.selfie => 'Selfie',
};
