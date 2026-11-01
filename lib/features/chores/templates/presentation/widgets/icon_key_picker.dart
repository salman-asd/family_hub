import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/presentation/chore_icons.dart';
import 'package:flutter/material.dart';

/// Picks one of the chore icons ([knownIconKeys]) (P3-16).
///
/// Used by the template editor and by the chore-group dialog of the settings
/// page, so the two can never offer different icon sets. The selected icon has
/// a heavier ring AND a check badge (never colour alone); every target is
/// 48 dp.
class IconKeyPicker extends StatelessWidget {
  const IconKeyPicker({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The chosen key, or null when none is chosen yet.
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final total = knownIconKeys.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < total; i++)
          Semantics(
            button: true,
            selected: knownIconKeys[i] == selected,
            enabled: enabled,
            label: '${l10n.choresGroupIcon} ${i + 1}',
            excludeSemantics: true,
            child: InkResponse(
              key: ValueKey<String>('icon_${knownIconKeys[i]}'),
              onTap: enabled ? () => onChanged(knownIconKeys[i]) : null,
              radius: 28,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: knownIconKeys[i] == selected ? t.accentSoft : null,
                  border: Border.all(
                    color: knownIconKeys[i] == selected
                        ? t.accentStrong
                        : t.outline,
                    width: knownIconKeys[i] == selected ? 3 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      choreIcon(knownIconKeys[i]),
                      size: 22,
                      color: knownIconKeys[i] == selected
                          ? t.accentStrong
                          : t.textPrimary,
                    ),
                    if (knownIconKeys[i] == selected)
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: t.accentStrong,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
