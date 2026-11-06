/// Screen-size classification used by every responsive layout (P4-24).
///
/// Pure: it takes numbers, never a `BuildContext`, so it is unit-testable and
/// importable from anywhere.  The thresholds follow the Material window size
/// classes, with one extra rule that matters for this app: a phone held in
/// landscape is still a *phone*, so the short side decides.
enum LayoutClass {
  /// Phones: portrait and landscape, and foldables while closed.
  compact,

  /// Portrait tablets and large foldables: wider content, still one column.
  medium,

  /// Tablets in landscape and desktop windows: side-by-side panes, two columns.
  expanded;

  /// Below this width there is only one column of anything.
  static const double mediumMinWidth = 600;

  /// From this width the two-pane and two-column layouts switch on.
  static const double expandedMinWidth = 840;

  /// A device narrower than this on its short side is a phone even when held
  /// sideways, and keeps the [LayoutClass.compact] layout.
  static const double phoneShortSide = 600;

  static LayoutClass of(double width, double shortestSide) {
    if (shortestSide < phoneShortSide) return LayoutClass.compact;
    if (width >= expandedMinWidth) return LayoutClass.expanded;
    if (width >= mediumMinWidth) return LayoutClass.medium;
    return LayoutClass.compact;
  }

  bool get isCompact => this == LayoutClass.compact;

  bool get isMedium => this == LayoutClass.medium;

  bool get isExpanded => this == LayoutClass.expanded;

  /// Two-pane pages and the two-column dashboard grid.
  bool get showsTwoPanes => isExpanded;
}
