import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The colours of the calendar's heat mode, hatch and dimmed days (P3-24,
/// Appendix B.4 / B.6).
///
/// Everything is DERIVED from the theme's tokens (the orange `chart` entry,
/// the background and the text inks), so no colour literal lives outside
/// `lib/app/theme/` and a new theme gets a ramp for free. The dark ramp uses
/// its own, gentler steps instead of an inverted light one: an amber wash on a
/// near-black background reaches 4.5:1 for the day number only up to about a
/// third of opacity.
///
/// `test/app/theme/heat_ramp_test.dart` asserts the contrast of every pair for
/// every registered theme (text 4.5:1, graphics 3:1).
@immutable
final class HeatRamp {
  const HeatRamp._({
    required this.tints,
    required this.ink,
    required this.outsideMonthText,
  });

  /// Number of tint steps (heat levels 1 … [steps]).
  static const int steps = 4;

  static const List<double> _lightAlphas = <double>[0.08, 0.16, 0.26, 0.36];
  static const List<double> _darkAlphas = <double>[0.10, 0.18, 0.26, 0.34];
  static const double _outsideAlpha = 0.75;
  static const double _hatchAlpha = 0.6;

  static final Expando<HeatRamp> _cache = Expando<HeatRamp>('HeatRamp');

  /// The ramp of [tokens] (built once per token instance).
  factory HeatRamp.of(AppTokens tokens) =>
      _cache[tokens] ??= HeatRamp._build(tokens);

  static HeatRamp _build(AppTokens t) {
    final dark =
        ThemeData.estimateBrightnessForColor(t.background) == Brightness.dark;
    final alphas = dark ? _darkAlphas : _lightAlphas;
    final base = t.chart[2];
    return HeatRamp._(
      tints: List<Color>.unmodifiable(<Color>[
        for (final alpha in alphas)
          Color.alphaBlend(base.withValues(alpha: alpha), t.background),
      ]),
      ink: t.textPrimary,
      outsideMonthText: Color.alphaBlend(
        t.textSecondary.withValues(alpha: _outsideAlpha),
        t.background,
      ),
    );
  }

  /// The fill of level 1 … [steps], light to strong. Index 0 is level 1.
  final List<Color> tints;

  /// The colour of text drawn on any tint (the theme's primary text).
  final Color ink;

  /// The date number of a day outside the shown month: dimmed, but still at
  /// least 3:1 against the background (B.6).
  final Color outsideMonthText;

  /// The fill for heat [level] (0 = none, so `null`; above [steps] = the
  /// strongest).
  Color? tintOf(int level) {
    if (level <= 0) return null;
    return tints[(level > steps ? steps : level) - 1];
  }

  /// The colour of the hatch lines drawn over [fill]: the primary ink at 60%,
  /// which stays at least 3.5:1 against the background and every tint.
  static Color hatchLine(AppTokens t, Color fill) =>
      Color.alphaBlend(t.textPrimary.withValues(alpha: _hatchAlpha), fill);
}
