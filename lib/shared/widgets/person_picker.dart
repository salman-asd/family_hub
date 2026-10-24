import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One person a [PersonPicker] can choose.
class PersonOption {
  const PersonOption({required this.id, required this.name, this.avatarKey});

  final String id;
  final String name;
  final String? avatarKey;
}

/// A horizontal row of avatars with names; tap one to choose it.
///
/// Selection is shown by a ring *and* a check mark, never colour alone.  With
/// [allowNone] a leading "No one" choice lets the user clear the selection
/// (the payer on an expense is optional, for example).  Plain values only: the
/// caller maps its members to [PersonOption]s.
class PersonPicker extends StatelessWidget {
  const PersonPicker({
    required this.options,
    required this.selectedId,
    required this.onChanged,
    required this.label,
    this.allowNone = false,
    super.key,
  });

  final List<PersonOption> options;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (allowNone)
                _Choice(
                  selected: selectedId == null,
                  name: context.l10n.personPickerNone,
                  onTap: () => onChanged(null),
                  avatar: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: t.outline),
                    ),
                    child: Icon(
                      Icons.person_off_outlined,
                      size: 20,
                      color: t.textSecondary,
                    ),
                  ),
                ),
              for (final option in options)
                _Choice(
                  selected: option.id == selectedId,
                  name: option.name,
                  onTap: () => onChanged(option.id),
                  avatar: AppAvatar(
                    id: option.id,
                    name: option.name,
                    avatarKey: option.avatarKey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.name,
    required this.onTap,
    required this.avatar,
  });

  final bool selected;
  final String name;
  final VoidCallback onTap;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusMd),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                          color: selected ? t.accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: avatar,
                    ),
                    if (selected)
                      PositionedDirectional(
                        end: -2,
                        bottom: -2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.accent,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: t.textOnAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 72,
                  child: Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
