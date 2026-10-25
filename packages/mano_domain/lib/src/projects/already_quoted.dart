import '../shared/data_failure.dart';

/// Tells the one-quote-per-provider refusal apart from other rejections.
extension AlreadyQuoted on DataFailure {
  /// The projects service answers a second quote with `AlreadyExists: …`.
  bool get isAlreadyQuoted => switch (this) {
    DataRejected(:final reason?) => reason.startsWith('AlreadyExists'),
    _ => false,
  };
}
