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

/// Each brief's line, the fragment set in flame, and its picture.
({String text, String? emphasis, String art}) briefCopy(
  IdentityFlowStep step,
) => switch (step) {
  IdentityFlowStep.backBrief => (
    text: 'Voltea tu identificación para tomar una foto de la parte de atrás',
    emphasis: 'Voltea tu identificación',
    art: 'assets/identity/cedula_back.jpg',
  ),
  IdentityFlowStep.selfieBrief => (
    text: '¿Tomamos tu selfie?',
    emphasis: null,
    art: 'assets/identity/selfie.jpg',
  ),
  _ => (
    text: 'Toma la foto del frente de tu cédula',
    emphasis: 'foto del frente',
    art: 'assets/identity/cedula.jpg',
  ),
};
