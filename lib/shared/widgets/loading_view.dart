import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Skeleton placeholder shown while a screen or list loads (Step 11).
///
/// Bars are sized from the available width — never from text — so the skeleton
/// keeps its shape at any text scale and cannot overflow.  The bars pulse
/// gently, unless the platform asks for reduced motion, in which case a single
/// static frame is drawn.
///
/// Accessibility: assistive technology hears one localized label ("Loading")
/// instead of a pile of empty boxes, and the pulse is announced as a live
/// region so a long load is not silent.
class LoadingView extends StatefulWidget {
  const LoadingView({
    this.lines = 3,
    this.showAvatar = false,
    this.semanticLabel,
    super.key,
  }) : assert(lines > 0, 'A skeleton needs at least one line');

  /// How many placeholder lines (rows) to draw.
  final int lines;

  /// Draws a circular placeholder on the leading edge, as a list row would.
  final bool showAvatar;

  /// Localized screen-reader label; defaults to the generic "Loading".
  final String? semanticLabel;

  /// Height of one bar, and diameter of the leading avatar placeholder.
  static const double barHeight = 12;
  static const double avatarSize = 40;

  /// Width used when the skeleton is laid out with unbounded width (for
  /// example inside a horizontal scroll view), so it still has a shape.
  static const double fallbackWidth = 320;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  static const double _gap = 12;
  static const double _shortLineFactor = 0.6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: widget.semanticLabel ?? context.l10n.loadingSemantics,
      liveRegion: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : LoadingView.fallbackWidth;
            final skeleton = _skeleton(t, width);
            if (reduceMotion) return skeleton;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: 0.45 + 0.4 * _controller.value,
                child: child,
              ),
              child: skeleton,
            );
          },
        ),
      ),
    );
  }

  /// The static skeleton, laid out to exactly [width] so a parent with
  /// unbounded constraints still gives it a shape.
  Widget _skeleton(AppTokens t, double width) {
    if (!widget.showAvatar) {
      return SizedBox(width: width, child: _lines(t, width));
    }

    // A very narrow slot leaves no room for a line beside the avatar.
    final lineWidth = width - LoadingView.avatarSize - _gap;
    if (lineWidth <= 0) {
      return SizedBox(width: width, child: _avatar(t));
    }

    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(t),
          const SizedBox(width: _gap),
          SizedBox(width: lineWidth, child: _lines(t, lineWidth)),
        ],
      ),
    );
  }

  Widget _lines(AppTokens t, double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.lines; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == widget.lines - 1 ? 0 : 8),
            child: _bar(t, _lineWidth(i, width)),
          ),
      ],
    );
  }

  /// The last of several lines is short: it reads as "a paragraph continues".
  double _lineWidth(int index, double width) {
    final isLast = index == widget.lines - 1;
    return isLast && widget.lines > 1 ? width * _shortLineFactor : width;
  }

  Widget _bar(AppTokens t, double width) => Container(
    width: width,
    height: LoadingView.barHeight,
    decoration: BoxDecoration(
      color: t.surfaceSunken,
      borderRadius: BorderRadius.circular(t.radiusSm),
    ),
  );

  Widget _avatar(AppTokens t) => Container(
    width: LoadingView.avatarSize,
    height: LoadingView.avatarSize,
    decoration: BoxDecoration(color: t.surfaceSunken, shape: BoxShape.circle),
  );
}
