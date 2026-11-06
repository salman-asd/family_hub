import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/heat_ramp.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// The key to heat mode (P3-24, B.4): "Less" - four tints - "More".
///
/// The swatches are shapes with a border, and the whole legend is announced as
/// ONE sentence, because the order of the tints (light to strong) is the
/// information, not each colour. It reads the ramp of the active theme, so the
/// light and the dark ramp each show their own steps.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final ramp = HeatRamp.of(t);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: t.textSecondary);
    return Semantics(
      container: true,
      label: l10n.calendarHeatLegendLabel,
      excludeSemantics: true,
      child: Wrap(
        key: const Key('calendar_heat_legend'),
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.calendarHeatLess, style: style),
          for (final tint in ramp.tints)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(t.radiusSm),
                border: Border.all(color: t.divider),
              ),
            ),
          Text(l10n.calendarHeatMore, style: style),
        ],
      ),
    );
  }
}
