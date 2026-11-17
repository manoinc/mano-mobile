import 'package:mano_domain/mano_domain.dart';

/// The fields [identityStatusFromJson] reads from a `WorkerVerification`.
const workerVerificationFields =
    'status attemptsRemaining '
    'latestAttempt { status declineReasons decisionReason }';

/// The gateway's `WorkerVerification` as the app's [IdentityCheckStatus].
IdentityCheckStatus identityStatusFromJson(Map<String, dynamic> json) {
  final attempt = json['latestAttempt'] as Map<String, dynamic>?;
  final attemptStatus = attempt?['status'] as String?;
  final canRetry = (json['attemptsRemaining'] as int? ?? 0) > 0;
  return switch ((json['status'] as String?, attemptStatus)) {
    ('VERIFIED', _) => const IdentityCheckApproved(),
    ('REJECTED', _) => IdentityCheckRejected(
      reason: _reason(attempt),
      canRetry: false,
    ),
    ('PENDING_REVIEW', _) ||
    ('IN_PROGRESS', 'PROCESSING') => const IdentityCheckPending(),
    (_, 'DECLINED') => IdentityCheckRejected(
      reason: _reason(attempt),
      canRetry: canRetry,
    ),
    (_, 'RESUBMISSION_REQUIRED') => IdentityCheckRejected(
      reason: _reason(attempt),
      canRetry: canRetry,
    ),
    // UNVERIFIED, or a session opened and left: Didit resumes it.
    _ => const IdentityCheckNotStarted(),
  };
}

String _reason(Map<String, dynamic>? attempt) {
  final declined = (attempt?['declineReasons'] as List?)?.cast<String>();
  final word = attempt?['decisionReason'] as String? ?? declined?.firstOrNull;
  return _copy[word] ?? _copy['OTHER']!;
}

// Generic on purpose: the staff's note never reaches the worker.
const _copy = {
  'DOCUMENT_UNREADABLE':
      'No pudimos leer tu cédula. Busca buena luz y evita reflejos.',
  'DOCUMENT_UNCLEAR':
      'No pudimos leer tu cédula. Busca buena luz y evita reflejos.',
  'DOCUMENT_EXPIRED': 'Tu documento está vencido. Usa uno vigente.',
  'DOCUMENT_NOT_SUPPORTED':
      'Ese documento no sirve. Usa tu cédula de ciudadanía.',
  'FACE_MISMATCH': 'Tu selfie no coincide con la foto de tu cédula.',
  'FACE_UNCLEAR':
      'No pudimos ver bien tu cara. Quítate gafas o gorra y busca buena luz.',
  'LIVENESS_FAILED': 'No pudimos confirmar que eras tú frente a la cámara.',
  'REGISTRY_MISMATCH':
      'Los datos de tu cédula no coinciden con la Registraduría.',
  'DUPLICATE_DOCUMENT': 'Esta cédula ya está registrada en otra cuenta.',
  'UNDERAGE': 'Necesitas ser mayor de edad para trabajar en Mano.',
  'BACKGROUND_CHECK': 'Tu verificación de antecedentes no fue aprobada.',
  'ATTITUDE': 'Tu perfil no cumple las políticas de Mano.',
  'IDENTITY_INCONSISTENCY': 'Encontramos inconsistencias en tu identidad.',
  'OTHER': 'No pudimos verificar tu identidad.',
};
