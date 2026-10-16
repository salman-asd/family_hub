/// Typed failures that cross layer boundaries inside a `Result`.
///
/// The UI maps each subtype to a localized message (Step 5); nothing in the
/// domain or data layers throws these.
sealed class AppFailure {
  const AppFailure();
}

/// The acting member lacks the required permission.
final class PermissionDenied extends AppFailure {
  const PermissionDenied();
}

/// A referenced document or entity does not exist.
final class NotFound extends AppFailure {
  const NotFound({this.entity});

  final String? entity;

  @override
  bool operator ==(Object other) => other is NotFound && other.entity == entity;

  @override
  int get hashCode => Object.hash('NotFound', entity);
}

/// Input failed a business or format rule. [field] names the input and
/// [code] is a stable machine-readable reason, for example `too_many_decimals`.
final class Validation extends AppFailure {
  const Validation(this.field, this.code);

  final String field;
  final String code;

  @override
  bool operator ==(Object other) =>
      other is Validation && other.field == field && other.code == code;

  @override
  int get hashCode => Object.hash('Validation', field, code);

  @override
  String toString() => 'Validation($field, $code)';
}

/// The operation conflicts with current state (last admin, locked month,
/// partly settled advance, already exists...).
final class Conflict extends AppFailure {
  const Conflict({this.code});

  final String? code;

  @override
  bool operator ==(Object other) => other is Conflict && other.code == code;

  @override
  int get hashCode => Object.hash('Conflict', code);
}

/// The network or backend was unreachable.
final class Network extends AppFailure {
  const Network();
}

/// Anything unexpected. [cause] is kept for logging only.
final class Unknown extends AppFailure {
  const Unknown([this.cause]);

  final Object? cause;
}
