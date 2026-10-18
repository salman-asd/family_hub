/// Where the current user stands on the way into the app.
///
/// Derived from auth state, profile existence and family membership by
/// `sessionPhaseProvider`.  Ordered exactly like the redirect rows in the
/// roadmap (Step 8): the first condition that holds wins.
enum SessionPhase {
  /// The first auth / profile / membership event has not arrived yet.
  loading,

  /// A backend read failed before the phase could be decided.  The splash
  /// screen shows a retry instead of spinning forever.
  failed,

  /// Not signed in.
  signedOut,

  /// Signed in, e-mail address not verified.
  needsVerification,

  /// Verified, but no user profile document yet.
  needsProfile,

  /// Profile exists, no family membership.
  needsFamily,

  /// Membership exists and waits for an admin.
  pending,

  /// Membership was disabled by an admin.
  disabled,

  /// Active member: the app proper.
  active,
}
