/// A signed-in identity.
///
/// This is the *authentication* view of a user — it deliberately carries no
/// profile or family data.  Profile and membership arrive in Step 9
/// (`features/onboarding`, `features/family`).
///
/// Pure Dart: no `flutter`, no `firebase`, no I/O.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  /// Firebase Auth uid.
  final String uid;

  /// Email address, if the provider exposes one.
  final String? email;

  /// Whether the address has been verified per roadmap Step 7.
  final bool emailVerified;

  AppUser copyWith({String? email, bool? emailVerified}) => AppUser(
        uid: uid,
        email: email ?? this.email,
        emailVerified: emailVerified ?? this.emailVerified,
      );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(uid, email, emailVerified);

  @override
  String toString() => 'AppUser($uid, email: $email, verified: $emailVerified)';
}
