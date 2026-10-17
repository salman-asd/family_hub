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

// ── Credential failures ───────────────────────────────────────────────────────
//
// `AppFailure` is a *sealed* class, so every subtype must live in this library.
// The credential failures below are produced only by the auth feature
// (Step 7), but they are declared here so that:
//
//   1. the `switch` in the auth feature's `authFailureCode` stays exhaustive —
//      adding a new subtype is a compile error until it is mapped to copy;
//   2. a new feature can reuse them without duplicating a parallel hierarchy.
//
// They deliberately do **not** reuse [Validation]: a rejected credential means
// "the input was well-formed but the backend refused it", which the UI must be
// able to tell apart from "you typed a bad email".

/// The email / password pair was rejected by the backend.
///
/// Firebase does not say *which* of the two was wrong (it returns
/// `invalid-credential`), so the UI must never guess either.
final class InvalidCredentials extends AppFailure {
  const InvalidCredentials();

  @override
  bool operator ==(Object other) => other is InvalidCredentials;

  @override
  int get hashCode => 0x101;
}

/// No account exists for this email.
final class UserNotFound extends AppFailure {
  const UserNotFound();

  @override
  bool operator ==(Object other) => other is UserNotFound;

  @override
  int get hashCode => 0x102;
}

/// The email is already attached to an account.
final class EmailAlreadyInUse extends AppFailure {
  const EmailAlreadyInUse();

  @override
  bool operator ==(Object other) => other is EmailAlreadyInUse;

  @override
  int get hashCode => 0x103;
}

/// The password did not satisfy the backend's policy.
final class WeakPassword extends AppFailure {
  const WeakPassword();

  @override
  bool operator ==(Object other) => other is WeakPassword;

  @override
  int get hashCode => 0x104;
}

/// Too many attempts; the backend is rate-limiting.
final class TooManyRequests extends AppFailure {
  const TooManyRequests();

  @override
  bool operator ==(Object other) => other is TooManyRequests;

  @override
  int get hashCode => 0x105;
}

/// The account is disabled (for example removed by Firebase support).
final class UserDisabled extends AppFailure {
  const UserDisabled();

  @override
  bool operator ==(Object other) => other is UserDisabled;

  @override
  int get hashCode => 0x106;
}

/// The backend requires a recent sign-in before this sensitive operation.
///
/// Surfaced for example when resending a verification email long after
/// sign-in, when the session is stale.
final class RequiresRecentLogin extends AppFailure {
  const RequiresRecentLogin();

  @override
  bool operator ==(Object other) => other is RequiresRecentLogin;

  @override
  int get hashCode => 0x107;
}

/// The backend rejected the email address as malformed.
///
/// Distinct from the purely local [Validation] check.
final class InvalidEmail extends AppFailure {
  const InvalidEmail();

  @override
  bool operator ==(Object other) => other is InvalidEmail;

  @override
  int get hashCode => 0x108;
}

/// The operation needs a signed-in user, but nobody is signed in.
///
/// Produced by the auth repository when a session-scoped call (for example
/// resending a verification email) is made with no `currentUser`.  The Step 8
/// router treats this as "go back to /welcome".
final class NoCurrentUser extends AppFailure {
  const NoCurrentUser();

  @override
  bool operator ==(Object other) => other is NoCurrentUser;

  @override
  int get hashCode => 0x109;
}
