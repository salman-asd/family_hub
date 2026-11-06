/// Compile-time switches for features that exist only as dormant code.
///
/// A flag is a `const`, so a disabled feature is removed by tree shaking and
/// cannot be reached by accident. Turning one on is a code change plus its own
/// step; nothing reads a flag from a server.
abstract final class FeatureFlags {
  /// True only when a push sender exists (Appendix I).
  static const bool pushBackend = false;

  /// The "Ask AI" entry on the dashboard (roadmap section 11). Dormant: the
  /// widget is built in P4-07 behind this flag and stays off.
  static const bool askAi = false;
}
