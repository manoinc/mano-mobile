/// What a marketplace port may report instead of a value.
sealed class DataFailure {
  const DataFailure();

  /// A short, non-technical description, suitable for showing a user.
  String get message;
}

final class DataNotFound extends DataFailure {
  const DataNotFound();

  @override
  String get message => 'No encontramos lo que buscabas.';

  @override
  String toString() => 'DataNotFound()';
}

/// The backend understood the request and refused it.
final class DataRejected extends DataFailure {
  const DataRejected({this.reason});

  /// What the backend said. Not for display.
  final String? reason;

  @override
  String get message => 'No pudimos completar esta acción.';

  @override
  String toString() => 'DataRejected(reason: $reason)';
}

/// The backend could not be reached or failed on its own side.
final class DataUnavailable extends DataFailure {
  const DataUnavailable({this.detail});

  /// Operational detail worth logging. Never show this to a user.
  final String? detail;

  @override
  String get message => 'Algo salió mal. Intenta de nuevo en un momento.';

  @override
  String toString() => 'DataUnavailable(detail: $detail)';
}

/// A wallet cannot cover a cost.
final class InsufficientCoins extends DataFailure {
  const InsufficientCoins({required this.needed, required this.available});

  final int needed;
  final int available;

  int get missing => needed - available;

  @override
  String get message => 'No tienes suficientes Mano coins.';

  @override
  String toString() =>
      'InsufficientCoins(needed: $needed, available: $available)';
}
