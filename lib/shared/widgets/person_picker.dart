import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One selectable person in a [PersonPicker].
@immutable
class PersonOption {
  const PersonOption({required this.id, required this.name, this.avatarKey});

  final String id;

  /// Display name, already localized by the caller (a member's name is data).
  final String name;

  /// Preset avatar key (`p0` … `p11`), or null to derive the colour from [id].
  final String? avatarKey;

  @override
  bool operator ==(Object other) =>
      other is PersonOption &&
      other.id == id &&
      other.name == name &&
      other.avatarKey == avatarKey;

  @override
  int get hashCode => Object.hash(id, name, avatarKey);
}

/// Horizontal avatar picker used by the expense and settle forms (P2-12).
///
/// Takes plain [PersonOption] values, so the widget never imports a feature or
/// Firebase.  Every target is at least 48dp; the row scrolls sideways when the
/// family has many members.  Selection is shown by a ring **and** a check
/// badge, never by colour alone.
class PersonPicker extends StatelessWidget {
  const PersonPicker({
    required this.options,
    required this.label,
    required this.onChanged,
    this.selectedId,
    this.allowNone = false,
    super.key,
  });

  final List<PersonOption> options;

  /// Localized caption above the row.
  final String label;

  /// Reports the chosen id, or null when the "none" option is chosen.
  final ValueChanged<String?> onChanged;

  /// Currently selected id; null means none.
  final String? selectedId;

  /// Shows a "none" target that reports null.  Useful for optional payers.
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allowNone) ...[
                _NoneChip(
                  label: l10n.personPickerNone,
                  selected: selectedId == null,
                  onTap: () => onChanged(null),
                ),
                const SizedBox(width: 8),
              ],
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PersonChip(
                    id: option.id,
                    name: option.name,
                    avatarKey: option.avatarKey,
                    selected: option.id == selectedId,
                    onTap: () => onChanged(option.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.id,
    required this.name,
    required this.selected,
    required this.onTap,
    this.avatarKey,
  });

  final String id;
  final String name;
  final String? avatarKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
          child: SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? t.accentStrong : t.outline,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: AppAvatar(
                          id: id,
                          name: name,
                          avatarKey: avatarKey,
                          size: 40,
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: t.accentStrong,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: t.textOnAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? t.textPrimary : t.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoneChip extends StatelessWidget {
  const _NoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
          child: SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surfaceSunken,
                      border: Border.all(
                        color: selected ? t.accentStrong : t.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person_off_outlined,
                      size: 20,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? t.textPrimary : t.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
