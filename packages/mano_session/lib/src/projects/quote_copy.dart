import 'package:mano_domain/mano_domain.dart';

// Quote copy both apps show; live profiles have no names yet.
const _placeholder = 'Profesional';

extension QuoteCopy on Quote {
  String get workerName => worker.nameOr(_placeholder);

  /// Up to two initials of [workerName], for an avatar without a photo.
  String get workerInitials => workerName
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  String get statusLabel => switch (status) {
    QuoteStatus.submitted => 'Enviada',
    QuoteStatus.selected => 'Elegida',
    QuoteStatus.discarded => 'No elegida',
  };
}

/// Tells "the project stopped taking quotes" apart from other refusals.
extension ClosedForQuotes on DataFailure {
  bool get isClosedForQuotes => switch (this) {
    DataRejected(:final reason?) => reason.startsWith('FailedPrecondition'),
    _ => false,
  };
}
