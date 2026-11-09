import 'package:flutter/widgets.dart';
import 'package:mano_session/mano_session.dart';

/// The person photographing their cédula, or taking a selfie, before each photo.
Widget identityArt(IdentityDocumentKind kind) => Image.asset(
  kind == IdentityDocumentKind.selfie
      ? 'assets/identity/selfie.jpg'
      : 'assets/identity/cedula.jpg',
  fit: BoxFit.cover,
  // The back crops toward the table, where the cédula lies.
  alignment: kind == IdentityDocumentKind.cedulaBack
      ? Alignment.bottomCenter
      : Alignment.topCenter,
  excludeFromSemantics: true,
);
