import '../shared/data_failure.dart';

/// Tells "this job can't be rated yet" apart from other rejections.
extension NotYetReviewable on DataFailure {
  /// The reviews service answers a job it hasn't seen finish with `FailedPrecondition: …`.
  bool get isNotYetReviewable => switch (this) {
    DataRejected(:final reason?) => reason.startsWith('FailedPrecondition'),
    _ => false,
  };
}
