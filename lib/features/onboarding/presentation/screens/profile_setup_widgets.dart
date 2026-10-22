import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// A small secondary-colour field label used by the profile form.
class ProfileLabel extends StatelessWidget {
  const ProfileLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.tokens.textSecondary),
    ),
  );
}

/// One preset avatar in the picker grid.
class ProfileAvatarChoice extends StatelessWidget {
  const ProfileAvatarChoice({
    required this.index,
    required this.name,
    required this.selected,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Number of presets offered by [AppAvatar].
  static const int presetCount = AppAvatar.presetCount;

  final int index;
  final String name;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        key: Key('avatar_$index'),
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppAvatar(
                id: 'p$index',
                name: name,
                avatarKey: 'p$index',
                size: 44,
              ),
              if (selected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: t.accentStrong,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
