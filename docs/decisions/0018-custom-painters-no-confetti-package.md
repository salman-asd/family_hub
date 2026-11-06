# 0018 - Celebration, plant and badges are CustomPainters; no confetti or Lottie package (decision D-P4-13)

**Status:** accepted (Phase 4, P4-01). Backs CLAUDE.md rules 66 and 67.

**Context.** Phase 4 needs a growing plant for the Hub Level, badge shapes and a
once-a-day celebration. The usual shortcuts are a confetti package or Lottie
files. Both add a dependency and a licence to check, Lottie assets are opaque
colour-wise (they ignore the two themes and the contrast tests), and neither
knows about reduced motion.

**Decision.**
- The plant, the badges and the confetti are `CustomPainter`s.
- A painter takes its **colours as arguments**, taken from `context.tokens` by
  the widget that owns it; a painter never reads a theme and never contains a
  colour literal (so the no-raw-colour test and both themes keep working).
- Animation lengths come from `engagementMotion(context)`, which is zero under
  `MediaQuery.disableAnimations`; with reduced motion the celebration is a
  static card.
- The only packages Phase 4 may add are `flutter_local_notifications`,
  `android_intent_plus` and `firebase_messaging` (CLAUDE.md rule 67). Not added:
  `confetti`, `lottie`, `workmanager`, `permission_handler`, `share_plus`, any
  drag-and-drop package (Flutter's `ReorderableListView` is enough).

**Consequences.** More code to write and test, but no dependency, no asset
licence, theme-correct colours in light and dark, and one place for motion
rules. A painter is tested by pumping it with token colours and by a golden.
