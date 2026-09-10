/// Sealed result type used at API and storage boundaries.
///
/// Internal code that cannot fail should not use `Result` — throw normally.
/// `Result` exists so HTTP/streaming layers can surface domain errors to the
/// UI without forcing every caller to wrap try/catch.
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get okOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  E? get errOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final error) => err(error),
      };

  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
        Ok(:final value) => Ok<U, E>(f(value)),
        Err(:final error) => Err<U, E>(error),
      };

  Result<T, F> mapErr<F>(F Function(E error) f) => switch (this) {
        Ok(:final value) => Ok<T, F>(value),
        Err(:final error) => Err<T, F>(f(error)),
      };
}

final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}
