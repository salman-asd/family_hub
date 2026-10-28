import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One person in an [AvatarStack].
class AvatarStackMember {
  const AvatarStackMember({
    required this.id,
    required this.name,
    this.avatarKey,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? avatarKey;
  final String? imageUrl;
}

/// Overlapping avatars with a "+N" bubble for the rest (P3-04).
///
/// Used where a chore's whole rotation or a group's members must fit in one
/// row (duty-group cards, the rota board). The avatars are decorative; the
/// stack announces one summarized label ("Dad, Mom and 2 more") so a screen
/// reader does not read a wall of names.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.members,
    this.maxVisible = 4,
    this.size = 28,
    this.overflowLabel,
    this.overflowSemanticLabel,
    this.onOverflowTap,
    super.key,
  });

  final List<AvatarStackMember> members;
  final int maxVisible;
  final double size;

  /// Text inside the "+N" bubble; defaults to "+N".
  final String? overflowLabel;

  /// Localized description of the whole stack. When null the stack is
  /// decorative and hidden from screen readers.
  final String? overflowSemanticLabel;

  /// Makes the "+N" bubble tappable (usually opens the member list).
  final VoidCallback? onOverflowTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final visible = members.take(maxVisible).toList();
    final hidden = members.length - visible.length;
    // The negative spacing is what makes them overlap.
    final overlap = size * 0.32;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : overlap),
            child: _Ringed(
              size: size,
              child: AppAvatar(
                id: visible[i].id,
                name: visible[i].name,
                avatarKey: visible[i].avatarKey,
                imageUrl: visible[i].imageUrl,
                size: size,
              ),
            ),
          ),
        if (hidden > 0)
          Padding(
            padding: EdgeInsets.only(left: overlap),
            child: _OverflowBubble(
              label: overflowLabel ?? l10n.avatarStackMoreShort(hidden),
              size: size,
              onTap: onOverflowTap,
            ),
          ),
      ],
    );

    if (overflowSemanticLabel == null) {
      return ExcludeSemantics(child: content);
    }
    return Semantics(
      label: overflowSemanticLabel,
      button: onOverflowTap != null,
      excludeSemantics: true,
      child: content,
    );
  }
}

/// A background-coloured ring so overlapping avatars stay separate shapes.
class _Ringed extends StatelessWidget {
  const _Ringed({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class _OverflowBubble extends StatelessWidget {
  const _OverflowBubble({
    required this.label,
    required this.size,
    required this.onTap,
  });

  final String label;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bubble = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surfaceSunken,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.outline),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return bubble;
    return InkResponse(onTap: onTap, radius: size * 0.6, child: bubble);
  }
}

/// Localized summary like "Rina and 2 more" for [AvatarStack.overflowSemanticLabel].
String avatarStackLabel(BuildContext context, String first, int rest) =>
    rest <= 0 ? first : context.l10n.avatarStackMore(first, rest);
