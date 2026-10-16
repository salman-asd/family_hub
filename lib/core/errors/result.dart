import 'package:family_hub/core/errors/app_failure.dart';

/// Outcome of a use case: either a [Success] value or a [Failure].
sealed class Result<T> {
  const Result();

  /// Folds the result into a single value.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  });

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => when<T?>(success: (v) => v, failure: (_) => null);

  AppFailure? get failureOrNull =>
      when<AppFailure?>(success: (_) => null, failure: (f) => f);

  /// Transforms the success value; failures pass through unchanged.
  Result<R> map<R>(R Function(T value) transform) => when<Result<R>>(
        success: (v) => Success<R>(transform(v)),
        failure: (f) => Failure<R>(f),
      );

  /// Chains another fallible step; the first failure wins.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      when<Result<R>>(
        success: transform,
        failure: (f) => Failure<R>(f),
      );
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) =>
      success(value);

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash('Success', value);

  @override
  String toString() => 'Success($value)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppFailure error;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) =>
      failure(error);

  @override
  bool operator ==(Object other) => other is Failure<T> && other.error == error;

  @override
  int get hashCode => Object.hash('Failure', error);

  @override
  String toString() => 'Failure($error)';
}
