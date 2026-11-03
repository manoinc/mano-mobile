import 'package:mano_domain/mano_domain.dart';

// Rating copy both apps show.

/// Why a rating was refused, in Spanish.
String reviewFailureCopy(DataFailure failure) => failure.isNotYetReviewable
    ? 'Aún no puedes calificar este trabajo. Intenta en unos minutos.'
    : 'No pudimos enviar tu calificación. Intenta de nuevo.';

/// What is wrong with a draft, in Spanish.
String reviewProblemCopy(ReviewDraftProblem problem) => switch (problem) {
  ReviewDraftProblem.noStars ||
  ReviewDraftProblem.starsOutOfRange => 'Elige de 1 a 5 estrellas.',
  ReviewDraftProblem.commentTooLong =>
    'Tu comentario es muy largo. Máximo 4000 caracteres.',
};
