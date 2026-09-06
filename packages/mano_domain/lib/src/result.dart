/// The outcome of an operation that is allowed to fail in a way the caller is
/// expected to handle.
///
/// Mano splits failure into two mechanisms, and which one applies is a
/// judgement about who made the mistake:
///
/// * **A [Result] carries a failure that is part of the contract.** The
///   backend was unreachable; the credentials were wrong; the record was not
///   found. Nobody wrote a bug — the world is simply like that sometimes, and
///   the caller is obliged to say what should happen next. Because [Result] is
///   sealed, the compiler makes sure they do.
/// * **A thrown [Error] means somebody wrote a bug.** An invariant was
///   violated, an argument was illegal, a branch that cannot happen happened.
///   These are never caught and never modelled: they should crash loudly in
///   development and be reported in production.
///
/// The practical consequence is that a failure a user can cause — a mistyped
/// password, a dropped connection — never travels as an exception. It is a
/// value, sitting in the state, impossible to confuse with a crash.
///
/// ```dart
/// switch (await sessionRepository.signIn()) {
///   case Ok(:final value):
///     // value is a Session
///   case Err(:final failure):
///     // failure is an AuthFailure, and the switch must cover every case
/// }
/// ```
sealed class Result<T, F> {
  const Result();

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T, F>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T, F>;

  /// The success value, or `null` when this is an [Err].
  ///
  /// Convenient at the edges. Prefer a `switch` where the failure matters:
  /// this collapses "failed" and "succeeded with null" into the same answer.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure, or `null` when this is an [Ok].
  F? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Applies [transform] to the success value, leaving a failure untouched.
  Result<R, F> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Applies [transform] to the failure, leaving a success untouched.
  ///
  /// Used by adapters to translate a lower-level failure into the vocabulary
  /// its port promises.
  Result<T, R> mapFailure<R>(R Function(F failure) transform) => switch (this) {
    Ok(:final value) => Ok(value),
    Err(:final failure) => Err(transform(failure)),
  };

  /// Chains another fallible step, short-circuiting on the first failure.
  Result<R, F> andThen<R>(Result<R, F> Function(T value) next) =>
      switch (this) {
        Ok(:final value) => next(value),
        Err(:final failure) => Err(failure),
      };

  /// Collapses both sides into a single value.
  R fold<R>(R Function(T value) onOk, R Function(F failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };
}

/// A successful [Result] carrying [value].
final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ok<T, F> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result] carrying [failure].
final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);

  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T, F> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
